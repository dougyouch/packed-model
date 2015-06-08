# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-
# stub: packed-model 0.2.0 ruby lib

Gem::Specification.new do |s|
  s.name = "packed-model"
  s.version = "0.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Doug Youch"]
  s.date = "2015-06-08"
  s.description = "Used to minimize storage space required to store list of data"
  s.email = "doug@sessionm.com"
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.rdoc"
  ]
  s.files = [
    ".document",
    "Gemfile",
    "Gemfile.lock",
    "LICENSE.txt",
    "README.rdoc",
    "Rakefile",
    "VERSION",
    "lib/packed_model.rb",
    "lib/packed_model/base.rb",
    "lib/packed_model/errors.rb",
    "lib/packed_model/list.rb",
    "packed-model.gemspec",
    "spec/helper.rb",
    "spec/packed_model/base_spec.rb",
    "spec/packed_model/list_spec.rb",
    "test/helper.rb",
    "test/test_packed_model_base.rb"
  ]
  s.homepage = "http://github.com/dyouch5@yahoo.com/packed-model"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.4.6"
  s.summary = "PackedModel stores model data in a binary string"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<jeweler>, [">= 0"])
      s.add_development_dependency(%q<rspec>, [">= 0"])
    else
      s.add_dependency(%q<jeweler>, [">= 0"])
      s.add_dependency(%q<rspec>, [">= 0"])
    end
  else
    s.add_dependency(%q<jeweler>, [">= 0"])
    s.add_dependency(%q<rspec>, [">= 0"])
  end
end

