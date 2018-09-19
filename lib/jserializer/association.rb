module Jserializer
  class Association
    attr_reader :relation_type, :serializer, :id_only

    def initialize(name, relation_type, key:, serializer:, id_only:, embed_key:)
      @attribute_name = name.to_s
      @relation_type = relation_type
      @key = key
      @serializer = serializer
      @id_only = id_only || false
      @embed_key = embed_key || :id
    end

    def key
      return @key if @key || !@id_only
      case @relation_type
      when :has_many
        :"#{singularize_attribute_name}_ids"
      when :has_one
        :"#{@attribute_name}_id"
      end
    end

    # The method name to access the data of the attribute
    def access_name
      return @attribute_name unless @id_only
      # for simplicity without guessing
      # the access method is post_ids for posts if associated with has_many
      # and post.id for post if associated with has_one
      # This also means for serializing a Hash object with has_one association
      # It must provide access key like "post.id" to get data
      case @relation_type
      when :has_many
        "#{singularize_attribute_name}_#{@embed_key}s"
      when :has_one
        "#{@attribute_name}.#{@embed_key}"
      else
        @attribute_name
      end
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
      serializer_object = klass.new(nil) if klass
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
        klass.new(record).serializable_hash
      else
        record.as_json(root: false)
      end
    end

    def find_serializer_class(model)
      return serializer if serializer
      return nil unless model.respond_to?(:active_model_serializer)
      model.active_model_serializer
    end

    def singularize_attribute_name
      return @attribute_name unless @attribute_name.end_with?('s')
      @attribute_name[0...-1]
    end
  end
end
