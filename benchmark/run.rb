require 'benchmark'
require 'jserializer'
require 'fast_jsonapi'
require 'active_model_serializers'
require_relative 'models'
require_relative 'jserializer_context'
require_relative 'ams_context'
require_relative 'fast_jsonapi_context'

blog = build_a_blog(
  num_posts: 100,
  num_users: 100,
  num_authors: 5,
  num_comments_per_post: 1000
)

GC.disable

Benchmark.bm(25) do |x|
  x.report("active_model_serializer:") do
    a = BlogAMSerializer.new(blog)
    a.serializable_hash
  end

  x.report("jserilaizer:") do
    j = BlogSerializer.new(blog)
    j.serializable_hash
  end

  x.report("fast_jsonapi:") do
    options = {}
    options[:include] = [
      :posts, :'posts.comments', :'posts.author',
      :'posts.comments.user'
    ]
    f = BlogFJSerializer.new(blog, options)
    f.serializable_hash
  end
end

GC.enable
