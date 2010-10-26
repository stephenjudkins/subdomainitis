require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Subdomainitis do
  class MocksController < ActionController::Metal

    def index
      request.env["rack.test.key"] = "expected value"
    end
  end

  before do
    @routes = ActionDispatch::Routing::RouteSet.new
    @routes.draw do
      extend Subdomainitis

      subdomain_as(:account) do
        resources :mocks
      end
    end
  end

  it "should not suppress changes made to the Rack env by the Rails app" do
    env = Rack::MockRequest.env_for("http://foo.test.host/mocks", {:method => :get})
    @routes.call(env)
    env["rack.test.key"].should == "expected value"
  end

end