module Jserializer
  class Base
    @_attributes = {}

    class << self
      attr_accessor :_attributes, :_root_key

      def attributes(*names)
        names.each { |name| attribute(name) }
      end

      def attribute(name, key: nil)
        self._attributes[name] = { key: key }
      end

      def root(name)
        self._root_key = name
      end

      # :serializer, :key, :embed, :embed_key
      def has_many(name, serializer: nil, key: nil)
        associate(name, :has_many, serializer: serializer, key: key)
      end

      def has_one(name, serializer: nil, key: nil)
        associate(name, :has_one, serializer: serializer, key: key)
      end

      def associate(name, type, serializer: nil, key: nil)
        sklass = serializer.is_a?(String) ? serializer.constantize : serializer
        association = Association.new(name, type, serializer: sklass)
        _attributes[name] = {
          association: association,
          key: key
        }
      end

      def inherited(subclass)
        super(subclass)
        subclass._attributes = _attributes.dup
      end
    end

    attr_reader :object, :options

    def initialize(object, options = {})
      @object = object
      @options = options
    end

    # reset object to reuse the serializer instance
    # clear any cached or memoized things
    def reset(object)
      @object = object
    end

    def serializable_hash
      result = {}
      self.class._attributes.each do |name, option|
        next unless _include_attribute?(name)
        result[option[:key] || name] = _set_value(name, option)
      end
      root_name ? { root_name => result } : result
    end

    def root_name
      return nil if options[:root] == false
      options[:root] || self.class._root_key
    end

    def to_json(*)
      ::Oj.dump(serializable_hash)
    end

    def as_json(_options = {})
      serializable_hash
    end

    private

    def _include_attribute?(name)
      include_method = "include_#{name}?".to_sym
      return true unless respond_to?(include_method)
      public_send(include_method)
    end

    def _set_value(name, option)
      return public_send(name) if respond_to?(name)
      if option.key?(:association)
        return _build_from_association(option[:association])
      end

      if ::Hash === object
        object.fetch(name)
      else
        object.public_send(name)
      end
    end

    def _build_from_association(association)
      association.serialize(object)
    end
  end
end
