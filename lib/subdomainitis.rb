module Subdomainitis

  SUBDOMAIN_KEY = "_subdomain"
  DEFAULT_TLD_LENGTH = 1

  class IsSubdomain
    def initialize(route_set)
      @route_set = route_set
    end
    attr_reader :route_set

    delegate :use_fake_subdomains, :tld_length, :to => :route_set

    def matches?(request)
      if use_fake_subdomains
        request.GET.has_key?(SUBDOMAIN_KEY)
      else
        request.subdomain(tld_length).present?
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

  class MainDomainRouteSet < ActionDispatch::Routing::RouteSet

    def initialize(parent_route_set)
      @parent_route_set = parent_route_set
      super *[]
    end
    attr_reader :parent_route_set

    def add_route(app, conditions = {}, requirements = {}, defaults = {}, name = nil, anchor = true)
      parent_route_set.add_maindomain_route name
      parent_route_set.add_route wrap(app), conditions, requirements, defaults, name, anchor
    end
    def wrap(app)
      ActionDispatch::Routing::Mapper::Constraints.new(
        app,
        [IsMaindomain.new(parent_route_set)],
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
    @set.maindomain_routes ||= {}
    maindomain_routeset = MainDomainRouteSet.new @set
    maindomain_routeset.draw &block
  end

  def use_fake_subdomains!
    @set.use_fake_subdomains = true
  end

  class RouteSetMiddleware
    def initialize(route_set, dispatcher, subdomain_key)
      @route_set, @dispatcher, @subdomain_key = route_set, dispatcher, subdomain_key
    end

    attr_reader :route_set, :subdomain_key, :dispatcher
    delegate :use_fake_subdomains, :tld_length, :to => :route_set

    PATH_PARAMETER_KEY = 'action_dispatch.request.path_parameters'

    def call(env)
      request = ActionDispatch::Request.new env

      path_parameters = env[PATH_PARAMETER_KEY].merge(subdomain_key => subdomain_from(request))
      env[PATH_PARAMETER_KEY] = path_parameters

      dispatcher.call(env)
    end

    def subdomain_from(request)
      if use_fake_subdomains
        request.GET[SUBDOMAIN_KEY]
      else
        request.subdomain(tld_length)
      end
    end
  end

  module RouteSetMethods
    def url_for_with_subdomains(args)
      route_name = args[:use_route]
      if subdomain_key = subdomain_routes[route_name]
        subdomain_url_for(subdomain_key, args.dup)
      elsif maindomain_routes[route_name]
        maindomain_url_for(args.dup)
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

    def maindomain_url_for(args)
      raise HostRequired.new if args[:only_path]

      url_for_without_subdomains(if use_fake_subdomains
        args
      else
        args.merge :host => main_domain_host(args[:host])
      end)
    end

    def add_subdomain_route(name, subdomain_key)
      subdomain_routes[name] = subdomain_key
    end

    def add_maindomain_route(name)
      maindomain_routes[name] = true
    end

    def host_name(subdomain_parameter, host)
      raise HostRequired.new unless host

      subdomain_parameter = if subdomain_parameter.respond_to?(:to_param)
        subdomain_parameter.to_param
      else
        subdomain_parameter
      end

      ([subdomain_parameter] + host.split(".")[subdomain_index..-1]).join(".")
    end

    def main_domain_host(host)
      host.split(".")[subdomain_index..-1].join(".")
    end

    def subdomain_index
      -1 - tld_length
    end

  end

  def self.extended(mapper)
    mapper.instance_variable_get(:@set).class_eval do
      include RouteSetMethods
      alias_method_chain :url_for, :subdomains
      attr_accessor :subdomain_routes, :maindomain_routes, :use_fake_subdomains, :tld_length
    end

    delegate :tld_length=, :to => :@set

    mapper.tld_length = DEFAULT_TLD_LENGTH
  end


  class HostRequired < Exception
    def initialize
      super("A hostname must be specified to generate this URL since it depends on a subdomain")
    end
  end

end
