def d(obj)
  puts ERB::Util.h(obj.inspect)
  puts "<br />"
end

require 'rubygems'
require 'bundler'
Bundler.setup

require 'rspec'
require 'rails/all'

require 'subdomainitis'
require 'subdomainitis/spec_helpers'


class SpecApplication < Rails::Application; end

SpecApplication.initialize!
