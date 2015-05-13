# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cf_message_bus/version'

Gem::Specification.new do |gem|
  gem.name = "cf-message-bus"
  gem.version = CfMessageBus::VERSION
  gem.authors = ["CloudFoundry Core Team"]
  gem.email = ["cfpi-dev@googlegroups.com"]
  gem.description = %q{Abstraction layer around NATS messaging bus}
  gem.summary = %q{Cloud Foundry message bus}
  gem.license = "Apache"

  gem.files = Dir["lib/**/*.rb"]
  gem.test_files = gem.files.grep(%r{^spec$})
  gem.require_paths = ["lib"]

  gem.add_development_dependency "bundler", "~> 1.3"
  gem.add_development_dependency "rspec"

  gem.add_dependency "eventmachine", "~> 1.0.0"
  gem.add_dependency "nats", ">= 0.5.0.beta.16", "< 0.6"
  gem.add_dependency "vcap-concurrency" # in the gemfile
end
