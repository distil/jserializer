module Jserializer
  class Association
    attr_reader :attribute_name, :relation_type, :serializer
    # Supported options:
    # :serializer, :embed, :embed_key
    def initialize(attribute_name, relation_type, serializer:)
      @attribute_name = attribute_name
      @relation_type = relation_type
      @serializer = serializer
    end

    def serialize(record)
      return serialize_to_array(record) if relation_type == :has_many
      return serialize_to_hash(record) if relation_type == :has_one
      raise "Unable to serialize association type: #{relation_type}"
    end

    private

    def serialize_to_array(record)
      children = record.public_send(attribute_name)
      return nil if children.nil?
      return [] if children.empty?

      klass = find_serializer_class(children.first)
      unless klass || children.first.respond_to?(:as_json)
        raise "Unable to find serializer for #{children.first.class.name}"
      end

      # initialize outside loop, so that we can reuse the serializer object
      serializer_object = klass.new(nil, root: false) if klass
      children.map do |child|
        if serializer_object
          serializer_object.reset(child)
          serializer_object.serializable_hash
        else
          child.as_json(root: false)
        end
      end
    end

    def serialize_to_hash(record)
      child = record.public_send(attribute_name)
      return nil if child.nil?

      klass = find_serializer_class(child)
      unless klass || child.respond_to?(:as_json)
        raise "Unable to find serializer for #{child.class.name}"
      end

      if klass
        klass.new(child, root: false).serializable_hash
      else
        child.as_json(root: false)
      end
    end

    def find_serializer_class(model)
      return serializer if serializer
      return nil unless model.respond_to?(:active_model_serializer)
      model.active_model_serializer
    end
  end
end
