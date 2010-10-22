# Subdomainitis: transparently use subdomains as parameters in Rails 3

### Installation and usage
To install, add `gem "subdomainitis"` to your `Gemfile`.  Then modify your routes.rb file; see the example below for usage.

    require 'subdomainitis'
    
    MyProject::Application.routes.draw do
      extend Subdomainitis
    
      resources :spams
    
      main_domain do
        resource :foos
      end
    
      subdomain_as(:account) do
        resources :bars
      end
    
      use_fake_subdomains! unless Rails.env.production?
    end

In the example above, the routes for `spams` will work regardless of the presence of a subdomain.  However, the `foos` routes will only work if accessed WITHOUT using a subdomain; only `http://mycompany.com/foos` will work.

Accessing `bars` routes will only work when a subdomain is provided.  Additionally, the specific subdomain is passed into the controller as a path parameter, as specified by the first argument to `subdomain_as`.  For example, `http://subdomain.mycompany.com/bars` resolves to `{:controller => 'bars', :action => 'index', :account => 'subdomain'}`.

URL generation should work transparently as well; make sure you're using url instead of path generation (ie, `foos_url` instead of `foos_path`).  Subdomainitis tries to fail fast by raising exceptions when a functional URL cannot be generated.

Call `use_fake_subdomains!` to use the `_subdomain` GET parameter instead of an actual subdomain.  This is useful for development where wildcard subdomains aren't possible, or for testing environments like Cucumber that don't support subdomains.  Enabling this mode should be completely transparent if you're using URL generators.

No changes to controllers are necessary.

### Issues
Though this library seems to work fine for me, there are probably bugs and untested corner cases.  Currently only named routes have been verified to work.

The implementation could probably be cleaner, and relies on internal Rails APIs that may be change in future versions.
