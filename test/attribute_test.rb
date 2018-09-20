require "test_helper"

class AttributeTest < Minitest::Test
  Person = Struct.new(:name, :age, :gender, :country)

  class PersonSerializer < Jserializer::Base
    attributes :name, :age
    attribute :gender
  end

  class PersonWithKeySerializer < Jserializer::Base
    attributes :name, :age
    attribute :gender, key: :type
  end

  class PersonInheritedSerializer < PersonWithKeySerializer
    attributes :country
  end

  class PersonOverwriteSerializer < PersonWithKeySerializer
    attributes :country
    attribute :gender, key: :g

    def gender
      object.gender == 'M' ? 'Male' : 'Female'
    end
  end

  class PersonIncludeSerializer < PersonWithKeySerializer
    attributes :country

    def include_country?
      !object.country.nil?
    end
  end

  class PersonWithRootSerializer < Jserializer::Base
    root :person
    attributes :name, :age
    attribute :gender
  end

  describe 'Attribute' do
    it 'adds attributes through #attribute or #attributes class methods' do
      person = Person.new('Sam', 20, 'M')
      serializer = PersonSerializer.new(person)
      result = serializer.serializable_hash
      assert_equal([:name, :age, :gender], result.keys)
      assert_equal(['Sam', 20, 'M'], result.values)
    end

    it 'renames the attribute with the :key option' do
      person = Person.new('Sam', 20, 'M')
      serializer = PersonWithKeySerializer.new(person)
      result = serializer.serializable_hash
      assert_equal([:name, :age, :type], result.keys)
      assert_equal(['Sam', 20, 'M'], result.values)
    end

    it 'inherits attributes from superclass' do
      person = Person.new('Sam', 20, 'M', 'USA')
      serializer = PersonInheritedSerializer.new(person)
      result = serializer.serializable_hash
      assert_equal([:name, :age, :type, :country], result.keys)
      assert_equal(['Sam', 20, 'M', 'USA'], result.values)
    end

    it 'overwrites the attribute key inherited from superclass' do
      person = Person.new('Sam', 20, 'M', 'USA')
      serializer = PersonOverwriteSerializer.new(person)
      result = serializer.serializable_hash
      assert_equal([:name, :age, :g, :country], result.keys)
    end

    it 'overwrites value by the method with the same name of the attribute' do
      person = Person.new('Sam', 20, 'M', 'USA')
      serializer = PersonOverwriteSerializer.new(person)
      result = serializer.serializable_hash
      assert_equal('Male', result[:g])
    end

    it 'includes attribute based on include_xxx? method' do
      sam = Person.new('Sam', 20, 'M')
      serializer = PersonIncludeSerializer.new(sam)
      result = serializer.serializable_hash
      refute_includes(result.keys, :country)

      bob = Person.new('Bob', 30, 'M', 'USA')
      serializer = PersonIncludeSerializer.new(bob)
      result = serializer.serializable_hash
      assert_includes(result.keys, :country)
    end

    it 'nests under a root key when calling as_json method' do
      person = Person.new('Sam', 20, 'M')
      serializer = PersonWithRootSerializer.new(person)
      result = serializer.as_json
      assert_equal([:person], result.keys)
      assert_equal([:name, :age, :gender], result[:person].keys)
    end

    it 'disables root key by passing root option to as_json method' do
      person = Person.new('Sam', 20, 'M')
      serializer = PersonWithRootSerializer.new(person)
      result = serializer.as_json(root: false)
      assert_equal([:name, :age, :gender], result.keys)
    end

    it 'sets root key when initialize serializer' do
      person = Person.new('Sam', 20, 'M')
      serializer = PersonWithRootSerializer.new(person, root: :account)
      result = serializer.as_json
      assert_equal([:account], result.keys)
      assert_equal([:name, :age, :gender], result[:account].keys)
    end

    it 'should not include the root when calling serializable_hash method' do
      person = Person.new('Sam', 20, 'M')
      serializer = PersonWithRootSerializer.new(person, root: :account)
      result = serializer.serializable_hash
      assert_equal([:name, :age, :gender], result.keys)
    end

    it 'disables root key when initialize serializer' do
      person = Person.new('Sam', 20, 'M')
      serializer = PersonWithRootSerializer.new(person, root: false)
      result = serializer.serializable_hash
      assert_equal([:name, :age, :gender], result.keys)
    end

    it 'dumps to json' do
      person = Person.new('Sam', 20, 'M')
      serializer = PersonWithRootSerializer.new(person)
      result = serializer.to_json
      assert_equal(
        '{"person":{"name":"Sam","age":20,"gender":"M"}}',
        result
      )
    end
  end
end
