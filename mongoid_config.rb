require "rubygems"
require "yaml"
require "mongoid"

configuration = YAML.load(File.read("mongoid.yml"))

Mongoid.configure do |config|
  config.from_hash(configuration)
end




