# Migration Guide
This document shares the process that we (Distil) used to migrate from `active_model_serializer` to `jserializer` in our Ruby on Rails applications. The main goal is to be able to migrate gradually without breaking anything in the meantime.

## Preparation
1. Add `jserializer` to Gemfile of your Rails application.
1. Create the `render_json` method in your `ApplicationController` (or similar class) that other controllers are inherited from.
    ```ruby
    class ApplicationController
      # ... ...

      # this method will be used to replace your `render json:` calls in the controllers 
      # that are ready to start using jserializer classes to render objects into JSON.
      def render_json(resource, options = {})
        if options.key?(:serializer)
          serializer = options.delete(:serializer)
        elsif options.key?(:each_serializer)
          serializer = options.delete(:each_serializer)
          options[:is_collection] = true
        end

        if !serializer && resource.respond_to?(:active_model_serializer)
          serializer = resource.active_model_serializer
        end

        if serializer
          options[:scope] = current_user
          options[:json] = serializer.new(resource, options)
        else
          options[:json] = resource
        end
        render options
      end
    end
    ```
1. Create the `ApplicationSerializer` class (or use another preferred name) that serves as the main class that other serializers will inherit from.
    ```ruby
    class ApplicationSerializer < Jserializer::Base
      # override this method to clean up instance variables, that
      # we don't want to persist over different objects, when
      # serializing a collection of records
      def reset(object)
        super
      end

      def to_json(*)
        ActiveSupport::JSON.encode(as_json)
      end
    end
    ```


## Upgrade Serializers
Most of the existing code of your serializer class should be compatible, the steps for transform it into a class 
that will be supported by `jserializer` are:
 1. Change the superclass of a serializer class from `ActiveModel::Serializer` to `ApplicationSerializer` 
 1. Does the class include `has_one` or `has_many` definitions? If yes, then read [Update Association](#update-association)
 1. Does it persist some kind of state by using instance variables `@xxxx` and memoization with `||=`? If yes, then read [Maintain State](#maintain-state)

### Update Association
`jserializer` does not guess the name of the serializer that would be used for the associations. Therefore, you need to specify the
`serializer` option explicitly, however, you don't need to do this if it only embeds ids, for example:
```ruby
class AccountSerializer < ApplicationSerializer
  # ... ...
  has_many :users, serializer: UserSerializer
  has_one :account_config, embed: :ids
end
```

Secondly, you need to recursively convert the serializers of the children resources to also use `jserializer`. It is recommended to use the bottom up approach for the migration. That is migrate those children models/serializers first and then their parents.

If embed id is used, Jserializer uses the following ways to retrieve data:

Type | Method | Example |
------------ | ------------- | -------------
|  has_many | `collection_singular_ids`  | `posts` => `post_ids`|
|  has_one |  `association.id` |  `account` => `account.id`  |

The way `jserializer` gets singular name is just by removing the `s`. If you are happy with the result. You can always directly create an overwrite method using the attribute name as method name in the serializer class for embedded ids, the same way you overwrite a normal attribute.

### Maintain State
`jserializer` tries to reuse only one serializer instance when serializing a collection of records, which could bring issue when the serializer keeps states from a previous record. You can handle this case by case, and also re-consider if it is really necessary to keep states in a serializer class.

1. You _probably_ don't need to maintain a state in a serializer class and it can probably be moved to the model.
2. If it is absolutely needed, you can override the `reset` method to clear any state, for example:
    ```ruby
    class MySerializer < Jserializer::Base
      ... ...
      def reset(object)
        @my_cached_stuff = nil
        ... ...
        super
      end
      ... ...
    end
    ```


## Upgrade Controllers

After finishing migrating serializers that are used for models in the response body of some action(s) in the controller, you
can start replace the render method to use `jserializer`.

### 1. Replace `render json:` with `render_json`. 

So that it can get rid of the hijacked version of `render` method by active_model_serializer, and start to use things from `jserializer`. 

Note that you don't need to replace `render json:` for `errors` object, simple hash or string that does not have a dedicated serializer class in `app/serializers` folder. As the serialization of these objects is handled by Rails' default encode method.

### 2. Add the `root` option is needed. 

`jserializer` does not guess the root name. If a root key is required in the response AND there is no `root` declaration in the serializer class, OR the root name will be different than the one declared in serializer class, then you need to explicitly pass `root: xxx` option to `render_json` method.