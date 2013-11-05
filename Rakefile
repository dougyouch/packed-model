# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "packed-model"
  gem.homepage = "http://github.com/dyouch5@yahoo.com/packed-model"
  gem.license = "MIT"
  gem.summary = "PackedModel stores model data in a binary string"
  gem.description = "Used to minimize storage space required to store list of data"
  gem.email = "doug@sessionm.com"
  gem.authors = ["Doug Youch"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new


