module Subdomainitis

  SUBDOMAIN_KEY = "_subdomain"

  class IsSubdomain
    def initialize(route_set)
      @route_set = route_set
    end
    attr_reader :route_set

    def matches?(request)
      if route_set.use_fake_subdomains
        request.GET.has_key?(SUBDOMAIN_KEY)
      else
        request.subdomain.present?
      end
    end
  end

  class IsMaindomain < IsSubdomain
    def matches?(request)
      !super(request)
    end
  end


  class SubdomainRouteSet < ActionDispatch::Routing::RouteSet
    def initialize(parent_route_set, subdomain_key)
      @parent_route_set, @subdomain_key = parent_route_set, subdomain_key
      super *[]
    end
    attr_reader :parent_route_set, :subdomain_key

    def add_route(app, conditions = {}, requirements = {}, defaults = {}, name = nil, anchor = true)
      parent_route_set.add_subdomain_route(name, subdomain_key)
      parent_route_set.add_route wrap(app), conditions, requirements, defaults, name, anchor
    end

    def wrap(app)
      ActionDispatch::Routing::Mapper::Constraints.new(
        RouteSetMiddleware.new(parent_route_set, app, subdomain_key),
        [IsSubdomain.new(parent_route_set)],
        request_class
      )
    end
  end

  def subdomain_as(subdomain_key, &block)
    @set.subdomain_routes ||= {}
    subdomain_routeset = SubdomainRouteSet.new @set, subdomain_key
    subdomain_routeset.draw &block
  end

  def main_domain(&block)
    constraints IsMaindomain.new(@set), &block
  end

  def use_fake_subdomains!
    @set.use_fake_subdomains = true
  end

  class RouteSetMiddleware
    def initialize(route_set, dispatcher, subdomain_key)
      @route_set, @dispatcher, @subdomain_key = route_set, dispatcher, subdomain_key
    end

    attr_reader :route_set, :subdomain_key, :dispatcher

    PATH_PARAMETER_KEY = 'action_dispatch.request.path_parameters'

    def call(env)
      request = ActionDispatch::Request.new env

      path_parameters = env[PATH_PARAMETER_KEY].merge(subdomain_key => subdomain_from(request))
      env = env.merge(PATH_PARAMETER_KEY => path_parameters)

      dispatcher.call(env)
    end

    def subdomain_from(request)
      if route_set.use_fake_subdomains
        request.GET[SUBDOMAIN_KEY]
      else
        request.subdomain
      end
    end
  end

  module RouteSetMethods
    def url_for_with_subdomains(args)
      if subdomain_key = subdomain_routes[args[:use_route]]
        subdomain_url_for(subdomain_key, args.dup)
      else
        url_for_without_subdomains args
      end
    end

    def subdomain_url_for(subdomain_key, args)
      raise HostRequired.new if args[:only_path]
      subdomain_parameter = args.delete(subdomain_key)
      raise HostRequired.new unless subdomain_parameter

      url_for_without_subdomains(if use_fake_subdomains
        args.merge SUBDOMAIN_KEY => subdomain_parameter
      else
        args.merge :host => host_name(subdomain_parameter, args[:host])
      end)
    end

    def add_subdomain_route(name, subdomain_key)
      subdomain_routes[name] = subdomain_key
    end

    def host_name(subdomain_parameter, host)
      raise HostRequired.new unless host
      ([subdomain_parameter] + host.split(".")[-2..-1]).join(".")
    end

  end

  def self.extended(router)
    router.instance_variable_get(:@set).class_eval do
      include RouteSetMethods
      alias_method_chain :url_for, :subdomains
      attr_accessor :subdomain_routes, :use_fake_subdomains
    end
  end

  class HostRequired < Exception
    def initialize
      super("A hostname must be specified to generate this URL since it depends on a subdomain")
    end
  end

end
