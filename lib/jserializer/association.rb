module Jserializer
  class Association
    attr_reader :relation_type, :serializer
    # Supported options:
    # :serializer, :embed, :embed_key
    def initialize(relation_type, serializer:)
      @relation_type = relation_type
      @serializer = serializer
    end

    def serialize(record)
      return nil if record.nil?
      return [] if relation_type == :has_many && record.empty?
      return serialize_collection(record) if relation_type == :has_many
      return serialize_one(record) if relation_type == :has_one
      raise "Unable to serialize association type: #{relation_type}"
    end

    private

    def serialize_collection(records)
      klass = find_serializer_class(records.first)
      unless klass || records.first.respond_to?(:as_json)
        raise "Unable to find serializer for #{records.first.class.name}"
      end

      # initialize outside loop, so that we can reuse the serializer object
      serializer_object = klass.new(nil, root: false) if klass
      records.map do |record|
        if serializer_object
          serializer_object.reset(record)
          serializer_object.serializable_hash
        else
          record.as_json(root: false)
        end
      end
    end

    def serialize_one(record)
      klass = find_serializer_class(record)
      unless klass || record.respond_to?(:as_json)
        raise "Unable to find serializer for #{record.class.name}"
      end

      if klass
        klass.new(record, root: false).serializable_hash
      else
        record.as_json(root: false)
      end
    end

    def find_serializer_class(model)
      return serializer if serializer
      return nil unless model.respond_to?(:active_model_serializer)
      model.active_model_serializer
    end
  end
end
