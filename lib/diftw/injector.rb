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
    # @return [Boolean] If true, the Injector injects singleton objects
    attr_reader :singleton
    # @return [Hash] A Hash containing all registered depencies (as procs) keyed by Symbols
    attr_reader :registry
    # @return [Hash] A Hash containing a Mutex for each dependency (only if singleton == true)
    attr_reader :mutexes

    private :registry, :mutexes

    #
    # Instantiate a new Injector.
    #
    #   DI = DiFtw::Injector.new
    #
    # @param singleton [Boolean] If true, each dependency will only be initialized once. When false, it will be initialized each time it's injected.
    #
    def initialize(singleton: true, &registrator)
      @registry, @mutexes = {}, {}
      @singleton = singleton
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
    # @return [Injector] returns the Injector object
    #
    def register(name, y = nil, &block)
      registry[name] = y || block
      mutexes[name] = Mutex.new if singleton
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
        instance_variable_get(var) || mutexes[name].synchronize {
          instance_variable_get(var) || instance_variable_set(var, registry.fetch(name).call)
        }
      else
        registry.fetch(name).call
      end
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
      injector_module.tap do |mod|
        mod._diftw_injector = self
        mod._diftw_dependencies = dependencies
      end
    end

    private

    #
    # Builds a new module that, when included in a class, defines instance methods for each dependecy.
    #
    # @return a new module
    #
    def injector_module
      Module.new do
        class << self
          attr_accessor :_diftw_injector, :_diftw_dependencies
        end

        def self.included(base)
          di_mod = self
          base.class_eval do
            di_mod._diftw_dependencies.each do |dep|
              define_method dep do
                var = "@_diftw_#{dep}"
                instance_variable_get(var) || instance_variable_set(var, di_mod._diftw_injector[dep])
              end
            end
          end
        end
      end
    end
  end
end
