# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sts_salesforce_org/version'

Gem::Specification.new do |spec|
  spec.name          = "sts_salesforce_org"
  spec.version       = StsSalesforceOrg::VERSION
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
end
