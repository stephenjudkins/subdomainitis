require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Subdomainitis do
  class BothsController; end
  class SubDomainOnlysController; end
  class MainDomainOnlysController; end

  subject { @routes }

  include Subdomainitis::SpecHelpers

  context "in production mode" do

    before do
      @routes = ActionDispatch::Routing::RouteSet.new
      @routes.draw do
        extend Subdomainitis

        main_domain do
          resources :boths, :as => :main_domain_boths
          resources :main_domain_onlys
        end

        subdomain_as(:account) do
          resources :boths, :as => :subdomain_boths
          resources :sub_domain_onlys
        end
      end
    end

    context "with identical routes on both domains" do
      describe "main domain routes" do
        it "should generate a URL to the main domain" do
          {:use_route => "main_domain_boths"}.should generate_url("http://test.host/boths")
        end

        it "should generate a route using named helpers" do
          url_helpers.main_domain_boths_url(:host => 'test.host').should == "http://test.host/boths"
        end

        it "should recognize the main domain" do
          "http://test.host/boths".should resolve_to(:controller => 'boths', :action => 'index')
        end
      end

      describe "subdomain routes" do
        it "should generate a URL to the given subdomain" do
          {:use_route => 'subdomain_boths', :account => 'foo'}.should generate_url("http://foo.test.host/boths")
        end

        it "should generate a route using named helpers" do
          url_helpers.subdomain_boths_url(:host => 'test.host', :account => 'foo').should == "http://foo.test.host/boths"
        end

        it "should recognize the route based on subdomain" do
          "http://foo.test.host/boths".should resolve_to(:controller => 'boths', :action => 'index', :account => 'foo')
        end
      end
    end

    context "with routes on only subdomains" do
      it "should generate a URL to the given subdomain (contigent on parameter)" do
        {:use_route => 'sub_domain_onlys', :account => 'foo'}.should generate_url("http://foo.test.host/sub_domain_onlys")
      end

      it "should generate a URL based on a parameter that has responds_to #to_param" do
        object = mock("object", :to_param => 'foo')
        {:use_route => 'sub_domain_onlys', :account => object}.should generate_url("http://foo.test.host/sub_domain_onlys")
      end

      it "should work when using named route helpers" do
        url_helpers.sub_domain_onlys_url(:host => 'test.host', :account => 'foo').
          should == "http://foo.test.host/sub_domain_onlys"
      end

      it "should recognize a route subdomain route" do
        "http://foo.test.host/sub_domain_onlys".should resolve_to(
          :controller => 'sub_domain_onlys',
          :account => 'foo',
          :action => 'index'
        )
      end

      it "should raise an error if no host is specified" do
        lambda {
         url_helpers.url_for(:use_route => 'sub_domain_onlys', :account => 'foo')
        }.should raise_error(Subdomainitis::HostRequired)
      end

      it "should raise an exception if only_path is specified" do
        lambda {
         url_helpers.url_for(:use_route => 'sub_domain_onlys', :account => 'foo', :host => 'foo.com', :only_path => true)
        }.should raise_error(Subdomainitis::HostRequired)
      end

      it "should raise an exception if a named _path helper is called" do
        lambda {
          url_helpers.sub_domain_onlys_path :account => 'foo', :host => 'foo.com'
        }.should raise_error(Subdomainitis::HostRequired)
      end

      it "should raise an error if the subdomain parameter is not specified" do
        lambda {
         url_helpers.url_for(:use_route => 'sub_domain_onlys', :host => 'test.host')
        }.should raise_error(Subdomainitis::HostRequired)

      end

    end

    context "with routes only on the main domain" do
      it "should generate a URL to the main domain" do
        {:use_route => 'main_domain_onlys', :host => "subdomain.test.host"}.should generate_url("http://test.host/main_domain_onlys")
      end

      it "should recognize the main domain route" do
        "http://test.host/main_domain_onlys".should resolve_to(:controller => 'main_domain_onlys', :action => 'index')
      end

      it "should not recognize a subdomain route on the main domain" do
        "http://foo.test.host/main_domain_onlys".should_not resolve_to(:controller => 'main_domain_onlys', :action => 'index')
        "http://foo.test.host/main_domain_onlys".should_not resolve_to(:controller => 'main_domain_onlys', :action => 'index', :account => 'foo')
      end
    end

  end

  context "in development mode" do
    before do
      @routes = ActionDispatch::Routing::RouteSet.new
      @routes.draw do
        extend Subdomainitis

        main_domain do
          resources :boths, :as => :main_domain_boths
          resources :main_domain_onlys
        end

        subdomain_as(:account) do
          resources :boths, :as => :subdomain_boths
          resources :sub_domain_onlys
        end

        use_fake_subdomains!
      end
    end

    context "with identical routes on both domains" do
      describe "main domain routes" do
        it "should generate a URL to the main domain" do
          {:use_route => "main_domain_boths"}.should generate_url("http://test.host/boths")
        end

        it "should generate a route using named helpers" do
          url_helpers.main_domain_boths_url(:host => 'test.host').should == "http://test.host/boths"
        end

        it "should recognize the main domain" do
          "http://test.host/boths".should resolve_to(:controller => 'boths', :action => 'index')
        end
      end

      describe "subdomain routes" do
        it "should generate a URL with the given _subdomain parameter" do
          {:use_route => 'subdomain_boths', :account => 'foo'}.should generate_url("http://test.host/boths?_subdomain=foo")
        end

        it "should recognize the route based on the _subdomain parameter" do
          "http://test.host/boths?_subdomain=foo".should resolve_to(:controller => 'boths', :action => 'index', :account => 'foo')
        end
      end
    end

    context "with routes on only subdomains" do
      it "should generate a URL to the given subdomain (contigent on parameter)" do
        {:use_route => 'sub_domain_onlys', :account => 'foo'}.should generate_url("http://test.host/sub_domain_onlys?_subdomain=foo")
      end

      it "should generate a URL based on a parameter that has responds_to #to_param" do
        object = mock("object", :to_param => 'foo')
        {:use_route => 'sub_domain_onlys', :account => object}.should generate_url("http://test.host/sub_domain_onlys?_subdomain=foo")
      end

      it "should recognize a route subdomain route" do
        "http://test.host/sub_domain_onlys?_subdomain=foo".should resolve_to(
          :controller => 'sub_domain_onlys',
          :account => 'foo',
          :action => 'index'
        )
      end
    end

    context "with routes only on the main domain" do
      it "should generate a URL to the main domain" do
        {:use_route => 'main_domain_onlys'}.should generate_url("http://test.host/main_domain_onlys")
      end

      it "should recognize the main domain route" do
        "http://test.host/main_domain_onlys".should resolve_to(:controller => 'main_domain_onlys', :action => 'index')
      end
    end


  end

  describe "with tld_length set" do
    before do
      @routes = ActionDispatch::Routing::RouteSet.new
      @routes.draw do
        extend Subdomainitis

        main_domain do
          resources :boths, :as => :main_domain_boths
          resources :main_domain_onlys
        end

        subdomain_as(:account) do
          resources :boths, :as => :subdomain_boths
          resources :sub_domain_onlys
        end

        self.tld_length = 2
      end
    end

    it "should recognize the third-level domain as subdomain" do
      "http://foo.bar.test.host/sub_domain_onlys".should resolve_to(
        :controller => 'sub_domain_onlys', :action => 'index', :account => 'foo')
    end

    it "should recognize second-level domains as main domain" do
      "http://bar.test.host/main_domain_onlys".should resolve_to(
        :controller => 'main_domain_onlys', :action => 'index')
    end

    it "should generate URLs to a four-level hostname" do
      {:use_route => 'sub_domain_onlys', :account => "foo", :host => "a.b.c"}.should generate_url("http://foo.a.b.c/sub_domain_onlys")
    end

    it "should generate main URLs with a three-level hostname" do
      {:use_route => 'main_domain_onlys', :host => "a.b.c"}.should generate_url("http://a.b.c/main_domain_onlys")
    end
  end


end