require 'rubygems'
require 'rake'
require 'echoe'

Echoe.new('vilango_tokenizer', '0.1.0') do |p|
  p.description    = "Create tokens from text with correct syntax {{S:Slug}}{{C:Character}} This is some random text."
  p.url            = "http://github.com/hfritz/vilango_tokenizer"
  p.author         = "vilango"
  p.email          = "all@vilango.com"
  p.ignore_pattern = ["tmp/*", "script/*"]
  p.development_dependencies = []
end

Dir["#{File.dirname(__FILE__)}/tasks/*.rake"].sort.each { |ext| load ext }
