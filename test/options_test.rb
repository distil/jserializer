require "test_helper"

class OptionsTest < Minitest::Test
  User = Struct.new(:id, :name, :password, :auth_key, :active)
  Account = Struct.new(:id, :company, :total_score)

  class UserSerializer < Jserializer::Base
    attributes :id, :name, :password, :auth_key, :active
  end

  class AccountSerializer < Jserializer::Base
    attributes :id, :company, :total_score

    def include_total_score?
      current_user.active
    end
  end

  describe 'Options' do
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

    describe 'Scope' do
      it 'sets scope through option[:scope]' do
        user = User.new(123, 'Sam', 'abc', 'top_secret', false)
        account = Account.new(1, 'New Account', 85)
        serializer = AccountSerializer.new(account, scope: user)
        result = serializer.serializable_hash
        assert_equal(user, serializer.scope)
        assert_equal([:id, :company], result.keys)
      end

      it 'sets scope through option[:current_user]' do
        user = User.new(123, 'Sam', 'abc', 'top_secret', false)
        account = Account.new(1, 'New Account', 85)
        serializer = AccountSerializer.new(account, current_user: user)
        result = serializer.serializable_hash
        assert_equal(user, serializer.scope)
        assert_equal([:id, :company], result.keys)
      end

      it 'alias scope with current_user' do
        user = User.new(123, 'Sam', 'abc', 'top_secret', false)
        account = Account.new(1, 'New Account', 85)
        serializer = AccountSerializer.new(account, current_user: user)
        assert_equal(user, serializer.current_user)
        assert_equal(user, serializer.scope)
      end
    end

    describe 'Meta' do
      it 'includes meta data through option[:meta]' do
        user = User.new(123, 'Sam', 'abc', 'top_secret', true)
        serializer = UserSerializer.new(user, meta: { score: 1 })
        result = serializer.as_json
        assert result.key?(:meta)
        assert_equal({ score: 1 }, result[:meta])
      end

      it 'changes the output name of meta through option[:meta_key]' do
        user = User.new(123, 'Sam', 'abc', 'top_secret', true)
        options = { meta: { score: 1 }, meta_key: :extra }
        serializer = UserSerializer.new(user, options)
        result = serializer.as_json
        assert result.key?(:extra)
        refute result.key?(:meta)
        assert_equal({ score: 1 }, result[:extra])
      end
    end
  end
end
