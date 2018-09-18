module Jserializer
  class Base
    @_attributes = {}

    class << self
      attr_accessor :_attributes, :_root_key

      def attributes(*names)
        names.each { |name| attribute(name) }
      end

      def attribute(name, key: nil)
        self._attributes[name] = {
          key: key,
          include_method: "include_#{name}?".to_sym
        }
        generate_attribute_methods(name)
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
        _attributes[name] = {
          key: key,
          include_method: "include_#{name}?".to_sym,
          association: Association.new(type, serializer: sklass)
        }
        generate_attribute_methods(name)
      end

      # Generate attribute access and inclusion check methods
      # This improves performance by avoiding method lookups like:
      #     public_send(name) if respond_to?(name)
      def generate_attribute_methods(name)
        class_eval <<-METHOD, __FILE__, __LINE__ + 1
          def #{name}
            if ::Hash === object
              object.fetch(#{name})
            else
              object.#{name}
            end
          end

          def include_#{name}?
            true
          end
        METHOD
      end

      def inherited(subclass)
        super(subclass)
        subclass._attributes = _attributes.dup
      end
    end

    attr_reader :object, :options, :current_user

    def initialize(object, options = {})
      @object = object
      @options = options
      @current_user = options[:current_user]
    end

    # reset object to reuse the serializer instance
    # clear any cached or memoized things
    def reset(object)
      @object = object
    end

    def serializable_hash
      result = {}
      self.class._attributes.each do |name, option|
        next unless public_send(option[:include_method])
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

    def _set_value(name, option)
      if option.key?(:association)
        return _build_from_association(name, option[:association])
      end
      public_send(name)
    end

    def _build_from_association(name, association)
      resource = public_send(name)
      association.serialize(resource)
    end
  end
end
