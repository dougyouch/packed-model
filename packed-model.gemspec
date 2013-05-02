# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{packed-model}
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Doug Youch"]
  s.date = %q{2013-05-02}
  s.description = %q{Used to minimize storage space required to store list of data}
  s.email = %q{doug@sessionm.com}
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
    "spec/helper.rb",
    "spec/packed_model/base_spec.rb",
    "spec/packed_model/list_spec.rb",
    "test/helper.rb",
    "test/test_packed_model_base.rb"
  ]
  s.homepage = %q{http://github.com/dyouch5@yahoo.com/packed-model}
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.6}
  s.summary = %q{PackedModel stores model data in a binary string}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rdoc>, ["~> 3.12"])
      s.add_development_dependency(%q<jeweler>, ["~> 1.8.4"])
      s.add_development_dependency(%q<rcov>, [">= 0"])
      s.add_development_dependency(%q<rspec>, [">= 0"])
    else
      s.add_dependency(%q<rdoc>, ["~> 3.12"])
      s.add_dependency(%q<jeweler>, ["~> 1.8.4"])
      s.add_dependency(%q<rcov>, [">= 0"])
      s.add_dependency(%q<rspec>, [">= 0"])
    end
  else
    s.add_dependency(%q<rdoc>, ["~> 3.12"])
    s.add_dependency(%q<jeweler>, ["~> 1.8.4"])
    s.add_dependency(%q<rcov>, [">= 0"])
    s.add_dependency(%q<rspec>, [">= 0"])
  end
end

