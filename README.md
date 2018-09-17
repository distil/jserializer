# JSerializer

A JSON Serializer for Ruby objects including Rails models.

A drop-in replacement of Active Model Serializer (target version: 0.8).

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

### Attributes

```ruby
class PersonSerializer < Jserializer::Base
  attributes :first_name, :last_name
  attribute :full_name, key: :username

  def full_name
    "#{object.first_name} #{object.last_name}"
  end

  def include_last_name?
    object.last_name.present?
  end
end
```

### Associations

```ruby
class PostSerializer < Jserializer::Base
  attributes :title, :content
  has_many :comments, serializer: CommentSerializer
  has_one :author, serializer: AuthorSerializer

  # filters comments to be serialized
  def comments
    object.comments.where(:created_at => 1.day.ago)
  end
end
```

## Compatibility & Migration

Currently, not compatible if:
- have `include_xxx?` as private methods
- override `attributes` in instance method
- override internal method `_xxx` (e.g. `_serializable_array`)
- cache
- some options: `:except`

Since we try to reuse serializer instances to avoid unnecessary object creations, make sure there is no things like `||=` in
the serializer class.

### active_model_serializer method
This gem will try to find and use the serializer of the model defined by `active_model_serializer` method:

```ruby
class Post < ActiveRecord::Base
  def active_model_serializer
    MyPostSerializer
  end
end
```

### Use in Rails Action Controller
Active Model Serializer overrides `render :json` in [ActionController::Serialization](https://github.com/rails-api/active_model_serializers/blob/0-8-stable/lib/action_controller/serialization.rb), which is convenient. But it touches Rails internal methods which could bring compatibility issues when upgrading Rails.

This gem does not provide such feature, but you can easily achieve it in application layer, for example:
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
Then you can use this `render_json` method whenever you need to call `render json: resource ...` in your controllers.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/distil/jserializer.
