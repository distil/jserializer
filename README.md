# JSerializer

JSerializer is a JSON Serializer for Ruby objects. It is designed to be a drop-in replacement of Active Model Serializer (target version: [0.8](https://github.com/rails-api/active_model_serializers/tree/0-8-stable)) with [better performance](benchmark/README.md).

JSerializer does not rely on Rails or Active Model, and only requires few dependencies which makes it easier to be used in general Ruby project.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'jserializer'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install jserializer

## Usage

### Define a Model
```ruby
Person = Struct.new(:id, :first_name, :last_name, :age, :gender, :country)
```

### Create a Serializer
```ruby
class PersonSerializer < Jserializer::Base
  root :user
  attributes :full_name, :age, :gender
  attribute :country, key: :country_code

  def full_name
    "#{object.first_name} #{object.last_name}"
  end

  def gender
    object.gender == 'm' ? 'Male' : 'Female'
  end

  def include_age?
    object.age >= 18
  end
end
```

### Generate JSON
```ruby
person = Person.new(1, 'John', 'Doe', 16, 'm', 'US')
serializer = PersonSerializer.new(person)

# generates a Hash => {:user=>{:full_name=>"John Doe", :gender=>"Male", :country_code=>"US"}}
serializer.as_json

# generates JSON => {"user":{"full_name":"John Doe","gender":"Male","country_code":"US"}}
serializer.to_json
```

### Generate JSON Collection
```ruby
persons = 2.times.map{|i| Person.new(i, 'Person', "#{i}", 17 + i, 'm', 'US') }
serializer = PersonSerializer.new(persons, is_collection: true)
serializer.to_json
```
You will get:
```json
{
  "user":[
    {
      "full_name":"Person 0",
      "gender":"Male",
      "country_code":"US"
    },
    {
      "full_name":"Person 1",
      "age":18,
      "gender":"Male",
      "country_code":"US"
    }
  ]
}
```


## Serializer Class Definition Options

Method       | Options       | Description
------------ | ------------- | -------------
root | N/A | Set the root key of the generated JSON
attributes | N/A | Define a list of fields separated by `,` to be exposed from a Ruby object
attribute | :key - The name in the JSON output | Similar to `attributes` but for one field
has_many | :serializer<br> :key<br> :embed <br> :embed_key<br> | Include a collection of objects with has many association
has_one | Same as has_many | Include a object with has one association
embed | :ids<br> :objects | Determine if only include IDs of the associations

### Example
This example shows you where to apply the above methods
```ruby
class PostSerializer < Jserializer::Base
  root :article
  embed :ids
  attributes :id, :title, :content
  attribute :writer, key: :written_by
  has_many :comments, serializer: CommentSerializer, embed: :objects
  has_one :author, serializer: AuthorSerializer, embed_key: :id
end
```

For associations, Jserializer uses the following ways to retrieve data:

Type | Method | Example |
------------ | ------------- | -------------
|  has_many | `collection_singular_ids`  | `posts` => `post_ids`|
|  has_one |  `association.id` |  `account` => `account.id`  |


## Initialization Options for Serializer Instance

| Options       | Description
| ------------- | -------------
root | Set the root key of the generated JSON, set it to `false` to disable
meta | Meta information to be included in the JSON output
meta_key | The key name of the meta information, the default is `:meta`
is_collection | Whether the given object is a collection or single object
only | An array of attributes to be included in the JSON output
except | An array of attributes to be excluded in the JSON output
current_user | Use for determine the authorization scope

### Example
```ruby
PostSerializer.new(posts,
                   root: :post,
                   meta: { page: 1, total: 100},
                   is_collection: true,
                   only: [:title, :content])
```

You can enable/disable root when initializing a serializer instance:
```ruby
PostSerializer.new(post, root: false)
```

Or when calling `as_json` method:
```ruby
# here the root option only accept a boolean value
# you cannot rename root at this point
PostSerializer.new(post).as_json(root: false)
```

You can always get the Hash representation without `root` and `meta` information by calling `serializable_hash`
```ruby
PostSerializer.new(post).serializable_hash
```

### Collection
The `active_serializer_model` gem includes the `ArraySerializer` class to handle collections. There are a lot of magics happening underneath when you pass a collection object into `render json: @xxx`, to allow `ArraySerializer` gets triggered automatically.

Unlike `active_serializer_model`, there is no separate serializer class for array. To serialize a collection, you need to set `is_collection: true` when initializing a new serializer
```ruby
serializer = PostSerializer.new(posts, is_collection: true)
serializer.serializable_hash # or serializer.as_json to include root
```

You can also call `serializable_collection` method directly which will ignore the `is_collection` option
```ruby
serializer = PostSerializer.new(posts)
serializer.serializable_collection
```


## Compatibility & Migration

Currently, this gem is not compatible with `active_serializer_model` if you:
- have `include_xxx?` as private method
- override the instance method `attributes`
- override any internal method `_xxx` (e.g. `_serializable_array`)
- expect serializer to automatically include a root for you
- expect serializer figures out if the object is a collection automatically

Since we try to reuse serializer instances to avoid unnecessary object creations, make sure there is no things like `||=` in the serializer class. Or you can override `reset` method to clean things out
```ruby
class MySerializer < Jserializer::Base
  ... ...
  def reset(object)
    @my_cached_stuff = nil
    ... ...
    super
  end
```

### active_model_serializer method
This gem will try to find and use the serializer class defined by `active_model_serializer` method in a model, if you don't specify `serializer` explicitly

```ruby
class Post < ActiveRecord::Base
  def active_model_serializer
    MyPostSerializer
  end
end
```

### Use in Rails Action Controller
Active Model Serializer overrides `render :json` in [ActionController::Serialization](https://github.com/rails-api/active_model_serializers/blob/0-8-stable/lib/action_controller/serialization.rb), which is convenient. But it touches Rails internal methods which could bring compatibility issues when upgrading Rails.

This gem does not provide such feature, but you can easily achieve it in application layer, for example, create a wrapper method for `render`:
```ruby
class ApplicationController < ActionController::Base
  # ... ...
  def render_json(resource, options = {})
    serializer = options.delete(:serializer)
    serializer ||= resource.respond_to?(:active_model_serializer) && resource.active_model_serializer
    if serializer
      options[:current_user] = current_user
      # ... ...
      render json: serializer.new(resource, options), options
    else
      render json: resource, options
    end
  end
end
```
Then you can use this `render_json` method whenever you need to call `render json: resource ...` in your controllers. And this is probably a good way to migrate gradually.

### Caching
This gem does not plan to implement the cache feature.


## Benchmark
[See here](benchmark/README.md)

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/distil/jserializer.
