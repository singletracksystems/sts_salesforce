# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sts_salesforce/version'

Gem::Specification.new do |spec|
  spec.name          = "sts_salesforce"
  spec.version       = StsSalesforce::VERSION
  spec.authors       = ["Singletrack Systems Ltd"]
  spec.email         = [""]
  spec.description   = ""
  spec.summary       = ""
  spec.homepage      = "http://www.singletracksystems.com"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec-rails", "= 2.12.2"
  spec.add_development_dependency "sqlite3"

  spec.add_dependency "rails", ">= 3.2.11"
  spec.add_dependency "attr_encrypted"
  spec.add_dependency "savon", "~> 1.2"
  spec.add_dependency "inherited_resources", "= 1.3.1"
  spec.add_dependency "activeadmin", ">= 0.5.1"

end
