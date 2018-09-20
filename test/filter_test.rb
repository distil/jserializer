require "test_helper"

class FilterTest < Minitest::Test
  User = Struct.new(:id, :name, :password, :auth_key, :active)

  class UserSerializer < Jserializer::Base
    attributes :id, :name, :password, :auth_key, :active
  end

  describe 'Attribute Filter' do
    it 'only includes attributes in the option[:only] list' do
      user = User.new(123, 'Sam', 'abc', 'top_secret', true)
      options = { only: [:name, :active] }
      serializer = UserSerializer.new(user, options)
      result = serializer.serializable_hash
      assert_equal(options[:only], result.keys)
    end

    it 'excludes attributes in the option[:except] list' do
      user = User.new(123, 'Sam', 'abc', 'top_secret', true)
      options = { except: [:password, :auth_key] }
      serializer = UserSerializer.new(user, options)
      result = serializer.serializable_hash
      assert_equal([:id, :name, :active], result.keys)
    end

    it 'ignores option[:except] if option[:only] exists' do
      user = User.new(123, 'Sam', 'abc', 'top_secret', true)
      options = { only: [:name], except: [:password, :auth_key] }
      serializer = UserSerializer.new(user, options)
      result = serializer.serializable_hash
      assert_equal([:name], result.keys)
    end
  end
end
