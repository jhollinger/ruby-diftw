module DiFtw
  class Injector
    attr_reader :singleton
    attr_reader :registry
    attr_reader :mutexes
    private :registry, :mutexes

    def initialize(singleton: false, &registrator)
      @registry, @mutexes = {}, {}
      @singleton = singleton
      instance_eval &registrator if registrator
    end

    def register(name, y = nil, &block)
      registry[name] = y || block
      mutexes[name] = Mutex.new if singleton
      self
    end

    def []=(name, y)
      register name, y
    end

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

    def inject(*dependencies)
      injector_module.tap do |mod|
        mod._diftw_injector = self
        mod._diftw_dependencies = dependencies
      end
    end

    private

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
