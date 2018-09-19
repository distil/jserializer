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


### Result

Run on my Mid 2014 15-inch Macbook Pro (2.2 GHz Intel Core i7, 16 GB 1600 MHz DDR3)

Using Ruby 2.3.7p456

```
                                user     system      total        real
active_model_serializer:    1.790000   0.030000   1.820000 (  1.813744)
jserilaizer:                0.620000   0.030000   0.650000 (  0.651212)
fast_jsonapi:               0.960000   0.080000   1.040000 (  1.037269)
```
