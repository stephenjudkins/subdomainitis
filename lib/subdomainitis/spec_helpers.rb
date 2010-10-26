module Subdomainitis
  module SpecHelpers
    extend RSpec::Matchers::DSL

    define :generate_url do |expected|

      match do |args|
        generate(args) == expected
      end

      failure_message_for_should do |args|
        "expected that #{generate(args).inspect} would be == #{expected.inspect}"
      end

    end

    define :resolve_to do |expected|
      match do |path|
        called = false

        controller_class = "#{expected[:controller].camelize}Controller".constantize
        controller_instance = mock(controller_class)
        controller_class.should_receive(:action).any_number_of_times.with(expected[:action]).and_return(controller_instance)

        controller_instance.should_receive(:call) do |env|
          env["action_dispatch.request.path_parameters"].symbolize_keys.should == expected.symbolize_keys

          called = true

          [200, {'Content-Type' => 'text/html'}, ['Not Found']]
        end.any_number_of_times

        env = Rack::MockRequest.env_for(path, {:method => :get})

        subject.call(env)

        called
      end
    end

    def generate(args)
      url_helpers.url_for({:host => 'test.host'}.merge(args))
    end

    def url_helpers
      subject.url_helpers
    end


  end
end