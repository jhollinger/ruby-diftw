module DiFtw
  class Injector
    attr_reader :singleton
    attr_reader :registry
    private :registry

    def initialize(singleton: false, &registrator)
      @registry = {}
      @singleton = singleton
      instance_eval &registrator if registrator
    end

    def register(name, y = nil, &block)
      registry[name] = y || block
      self
    end

    def []=(name, y)
      registry[name] = y
      self
    end

    def [](name)
      if singleton
        var = "@_singleton_#{name}"
        instance_variable_get(var) || instance_variable_set(var, registry.fetch(name).call)
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
