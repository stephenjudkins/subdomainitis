Gem::Specification.new do |s|
  s.name        = "subdomainitis"
  s.version     = "0.9.3"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Stephen Judkins"]
  s.email       = ["stephen.judkins@gmail.com"]
  s.homepage    = "http://github.com/stephenjudkins/subdomainitis"
  s.summary     = "Easy routing based on subdomains for Rails 3"
  s.description = "subdomainitis provides easy, simple support for using wildcard subdomains as controller parameters in Rails 3"

  s.required_rubygems_version = ">= 1.3.6"

  s.add_development_dependency "rspec"
  # the implementation is tied pretty closely to Rails internals API, so I'm locking to specific version for now
  s.add_dependency "rails", ">= 3.0.3"

  s.files        = Dir.glob("{bin,lib}/**/*") + %w(LICENSE README.md)
  s.require_path = 'lib'
end
