## Benchmark

This folder contains several models and seed generation for a basic benchmark.

This benchmark compares `jserializer` gem against `active_model_serializer` gem (v0.8) and `fast_jsonapi` gem.

Note that it's not really apples-to-apples comparison with `fast_jsonapi`, since the output structure is quite different. But we can still give us a general feel of how the speed should look like when serializing similar amount of data.

### Run the benchmark
First, install necessary dependencies:

  $ bundle install

then

  $ bundle exec ruby run.rb

### Files
- `xxx_context.rb` contains serializer class definitions
- `models.rb` contains model definitions, and seed generation functions
- `run.rb` is the main file to run benchmark
