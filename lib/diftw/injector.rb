#
# Dependency Injection For The Win!
#
module DiFtw
  #
  # The Injector class. Create an instance to start registering and injecting dependencies.
  #
  #   DI = DiFtw::Injector.new
  #
  #   # You can call register on the Injector object
  #   DI.register :bar do
  #     Bar.new
  #   end
  #
  #   # Or you can assign a Proc to the Injector object like a Hash
  #   DI[:baz] = -> { Baz.new }
  #
  # Alternatively, you can pass a block to the initializer and register your depencies right inside it:
  #
  #   DI = DiFtw::Injector.new do
  #     register :foo do
  #       Foo.new
  #     end
  #
  #     register(:bar) { Bar }
  #   end
  #
  class Injector
    # @return [DiFtw::Injector] The parent injector, if any
    attr_reader :parent
    # @return [Hash] A Hash containing all registered depencies (as procs) keyed by Symbols
    attr_reader :registry

    protected :registry
    private :parent

    #
    # Instantiate a new Injector.
    #
    #   DI = DiFtw::Injector.new
    #
    def initialize(parent: nil, &registrator)
      @registry, @parent = {}, parent
      instance_eval &registrator if registrator
    end

    #
    # Register a new dependency by passing a Proc or a block.
    #
    #   DI.register :foo do
    #     Foo
    #   end
    #
    #   DI.register :bar, -> { Bar }
    #
    # @param name [Symbol] name of the dependency
    # @param y [Proc] the dependency wrapped in a Proc or block
    # @return [DiFtw::Injector] returns the Injector object
    #
    def register(name, y = nil, &block)
      registry[name] = Dependency.new(y || block, singleton: false)
      self
    end

    #
    # Register a new dependency as a singleton. The proc will only be called
    # the first time, then the returned value will be stored and returned for
    # subsequent injections. Threadsafe.
    # 
    #   DI.singleton :foo do
    #     Foo
    #   end
    #
    #   DI.singleton :bar, -> { Bar }
    #
    # @param name [Symbol] name of the dependency
    # @param y [Proc] the dependency wrapped in a Proc or block
    # @return [DiFtw::Injector] returns the Injector object
    # 
    def singleton(name, y = nil, &block)
      registry[name] = Dependency.new(y || block, singleton: true)
      self
    end

    #
    # Fetches a dependency by name (calls the Proc/block).
    #
    # @return whatever the Proc/block returns
    #
    def fetch(name)
      if parent.nil?
        registry.fetch(name).resolve
      elsif registry.has_key? name
        registry[name].resolve
      else
        parent[name]
      end
    end

    alias_method :[], :fetch

    #
    # Unregisters the dependency from this injector instance. This means requests for this dependency
    # will continue on up the chain.
    #
    # @param name [Symbol] name of the dependency
    # @return [DiFtw::Injector] returns the Injector object
    #
    def delete(name)
      registry.delete name
      self
    end

    #
    # Creates and returns a new Module which contains instance methods for all the dependencies you specified.
    # Simply include this module in your class, and all it's instances will have their dependencies injected.
    # Or extend your class with this module, and your class *itself* will have the dependencies injected.
    #
    #   class Widget
    #     include DI.inject :foo, :bar
    #   end
    #   Widget.new.foo
    #
    #   class Spline
    #     extend Di.inject :foo
    #   end
    #   Spline.foo
    #
    # @param dependencies [Symbol] All dependency names you want to inject.
    #
    def inject(*dependencies)
      DiFtw::Builder.injector_module self, dependencies
    end

    #
    # Injects dependencies into a specific, existing object.
    #
    #   DI.inject_instance obj, :foo, :bar
    #
    # @param instance [Object] The object you wish to inject dependencies into
    # @param dependencies [Symbol] All dependency names you want to inject.
    #
	def inject_instance(instance, *dependencies)
      mod = DiFtw::Builder.injector_module self, dependencies
      instance.singleton_class.send :include, mod
	end
  end
end
