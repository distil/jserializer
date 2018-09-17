# JSerializer

Build JSON objects from any Ruby Object including Rails Model.

A drop in replacement for Active Model Serializer (target version: v0.8)

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

TODO: Write usage instructions here

## Compatibility
Not compatible if you:
- have `include_xxx?` as private methods
- override `attributes` in instance method
- override internal method `_xxx` (e.g. `_serializable_array`)
- cache
- some options: `:except`

Since we try to reuse serializer instances to avoid unnecessary object creations, make sure there is no things like `||=` in
the serializer class.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/jserializer.
