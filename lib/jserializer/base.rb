module Jserializer
  class Base
    @_attributes = {}
    @_embed = :objects

    class << self
      attr_accessor :_attributes, :_root_key, :_embed

      def attributes(*names)
        names.each { |name| _add_attribute(name, nil) }
      end

      def attribute(name, key: nil)
        _add_attribute(name, key)
      end

      def root(name)
        self._root_key = name
      end

      # Define how associations should be embedded.
      #
      #   embed :objects # Embed associations as full objects
      #   embed :ids     # Embed only the association ids
      #
      def embed(type = :objects)
        self._embed = type
      end

      # embed: :objects || :ids
      # the embed_key only works when embed: ids
      def has_many(name, serializer: nil, key: nil, embed: nil, embed_key: nil)
        association = _build_association(
          name, :has_many, key, serializer, embed, embed_key
        )
        _add_attribute(name, key, association: association)
      end

      def has_one(name, serializer: nil, key: nil, embed: nil, embed_key: nil)
        association = _build_association(
          name, :has_one, key, serializer, embed, embed_key
        )
        _add_attribute(name, key, association: association)
      end

      def _build_association(name, type, key, serializer, embed, embed_key)
        id_only = embed == :ids || (embed.nil? && self._embed == :ids)
        Association.new(
          name, type,
          key: key, serializer: serializer,
          id_only: id_only, embed_key: embed_key
        )
      end

      def _add_attribute(name, key, association: nil)
        self._attributes[name] = {
          key: key,
          include_method: "include_#{name}?".to_sym
        }
        if association
          self._attributes[name][:association] = association
          self._attributes[name][:key] = association.key
        end
        access_name = association ? association.access_name : name
        generate_attribute_methods(name, access_name)
      end

      # Generate attribute access and inclusion check methods
      # This improves performance by avoiding method lookups like:
      #     public_send(name) if respond_to?(name)
      def generate_attribute_methods(name, access_name)
        class_eval <<-METHOD, __FILE__, __LINE__ + 1
          def #{name}
            if ::Hash === @object
              @object.fetch(#{access_name})
            else
              @object.#{access_name}
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

    # Returns a hash representation without the root
    def serializable_hash
      self.class._attributes.each_with_object({}) do |(name, option), hash|
        if public_send(option[:include_method])
          hash[option[:key] || name] = _set_value(name, option)
        end
      end
    end

    def root_name
      return nil if @options[:root] == false
      @options[:root] || self.class._root_key
    end

    def meta_key
      @options[:meta_key] || :meta
    end

    def to_json(*)
      ::Oj.dump(as_json)
    end

    # Returns a hash representation with the root
    # Available options:
    # :root => true or false
    def as_json(options = {})
      root = options.key?(:root) ? options[:root] : true
      hash = if root && root_name
               { root_name => serializable_hash }
             else
               serializable_hash
             end
      hash[meta_key] = @options[:meta] if @options.key?(:meta)
      hash
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
      return resource if association.id_only
      association.serialize(resource)
    end
  end
end
