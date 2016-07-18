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
    # @return [Boolean] If true, the Injector injects singleton objects
    attr_reader :singleton
    # @return [Hash] A Hash containing all registered depencies (as procs) keyed by Symbols
    attr_reader :registry
    # @return [Hash] A Hash containing a Mutex for each dependency (only if singleton == true)
    attr_reader :mutexes

    protected :registry, :mutexes
    private :parent

    #
    # Instantiate a new Injector.
    #
    #   DI = DiFtw::Injector.new
    #
    # @param singleton [Boolean] If true, each dependency will only be initialized once. When false, it will be initialized each time it's injected.
    #
    def initialize(singleton: true, parent: nil, &registrator)
      @registry, @parent = {}, parent
      @singleton = parent ? parent.singleton : singleton
      @mutexes = (parent ? parent.mutexes.keys : []).
        inject({}) { |a, name| a[name] = Mutex.new; a }
      @metamutex = Mutex.new
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
      registry[name] = y || block
      if singleton
        instance_variable_set "@_singleton_#{name}", nil
        mutexes[name] ||= Mutex.new
      end
      self
    end

    #
    # Register a new dependency by passing a Proc or a block.
    #
    #   DI[:foo] = -> { Foo }
    #
    # @param name [Symbol] name of the dependency
    # @param y [Proc] the dependency wrapped in a Proc
    #
    def []=(name, y)
      register name, y
    end

    #
    # Fetches a dependency by name (calls the Proc/block). If this is a Singleton injector,
    # the same object will be returned each time. Otherwise a new one will be returned each time.
    #
    # An application will probably never want to call this directly.
    #
    # @return whatever the Proc/block returns
    #
    def [](name)
      if singleton
        var = "@_singleton_#{name}"
        instance_variable_get(var) || mutex(name).synchronize {
          instance_variable_get(var) || instance_variable_set(var, resolve!(name))
        }
      else
        resolve! name
      end
    end

    #
    # Unregisters the dependency from this injector instance. This means requests for this dependency
    # will continue on up the chain.
    #
    # @param name [Symbol] name of the dependency
    # @return [DiFtw::Injector] returns the Injector object
    #
    def delete(name)
      registry.delete name
      if singleton
        instance_variable_set "@_singleton_#{name}", nil
      end
      self
    end

    #
    # Creates and returns a new Module which contains instance methods for all the dependencies you specified.
    # Simply include this module in your class, and all it's instances will have their dependencies injected.
    #
    #   class Widget
    #     include DI.inject(:foo, :bar)
    #   end
    #
    # @param dependencies [Symbol] All dependency names you want to inject.
    #
    def inject(*dependencies)
      DiFtw::Builder.injector_module self, dependencies
    end

    #
    # Injects dependencies into a specific, existing object.
    #
    #   DI.inject_instance(obj, :foo, :bar)
    #
    # @param instance [Object] The object you wish to inject dependencies into
    # @param dependencies [Symbol] All dependency names you want to inject.
    #
	def inject_instance(instance, *dependencies)
      mod = DiFtw::Builder.injector_module self, dependencies
      instance.singleton_class.send :include, mod
	end

    protected

    #
    # Recursively look up a dependency
    #
    # @param dependency [Symbol] name of dependency
    # @return [Proc]
    #
    def resolve!(dependency)
      if parent.nil?
        registry.fetch(dependency).call
      elsif registry.has_key? dependency
        registry[dependency].call
      else
        parent[dependency]
      end
    end

    private

    def mutex(name)
      return mutexes[name] unless mutexes[name].nil?
      @metamutex.synchronize {
        mutexes[name] = Mutex.new
      }
    end
  end
end
