# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{vilango_tokenizer}
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["vilango"]
  s.date = %q{2011-02-01}
  s.description = %q{Create tokens from text with correct syntax {{S:Slug}}{{C:Character}} This is some random text.}
  s.email = %q{all@vilango.com}
  s.extra_rdoc_files = ["README.rdoc", "lib/vilango_tokenizer.rb"]
  s.files = ["README.rdoc", "Rakefile", "lib/vilango_tokenizer.rb", "Manifest", "vilango_tokenizer.gemspec"]
  s.homepage = %q{http://github.com/hfritz/vilango_tokenizer}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Vilango_tokenizer", "--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{vilango_tokenizer}
  s.rubygems_version = %q{1.4.2}
  s.summary = %q{Create tokens from text with correct syntax {{S:Slug}}{{C:Character}} This is some random text.}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
