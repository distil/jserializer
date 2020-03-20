
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "jserializer"
  spec.version       = "0.2.1"
  spec.authors       = ["Steven Yue"]
  spec.email         = ""

  spec.summary       = %q{A JSON Serializer for Ruby Objects}
  spec.description   = %q{A simple JSON serializer used as a drop-in replacement of Active Model Serializer}
  spec.homepage      = "http://www.github.com/distil/jserializer"
  spec.license       = 'MIT'

  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = Dir["lib/**/*"]
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.0.0'

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest", "~> 5.0"
end
