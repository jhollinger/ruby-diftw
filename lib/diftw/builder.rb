module DiFtw
  #
  # Module for building various things, like other modules.
  #
  module Builder
    #
    # Builds a new module that, when included in a class, defines instance methods for each dependecy.
    #
    # @param parent_injector [DiFtw::Injector] The parent injector
    # @param dependencies [Symbol] All dependency names you want to inject
    # @return [Module] A module with accessor methods defined for each dependency
    #
    def self.injector_module(parent_injector, dependencies)
      Module.new {
        class << self
          attr_accessor :injector, :_diftw_dependencies
        end

        def self.included(base)
          di_mod = self
          base.class_eval do
            # Set the injector for the whole class
            class << self; attr_reader :injector; end
            @injector = di_mod.injector

            # Create a new injector for each instance
            define_method :injector do
              @injector ||= Injector.new(parent: di_mod.injector)
            end

            # Define a method to eager-inject all dependencies
            define_method :inject! do
              di_mod._diftw_dependencies.each do |dep|
                send dep
              end
              nil
            end

            # Define instance accessor methods
            di_mod._diftw_dependencies.each do |dep|
              define_method dep do
                var = "@_diftw_#{dep}"
                instance_variable_get(var) || instance_variable_set(var, self.injector[dep])
              end
            end
          end
        end

        def self.extended(base)
          di_mod = self
          base.singleton_class.class_eval do
            include di_mod
          end
        end
      }.tap { |mod|
        mod.injector = Injector.new(parent: parent_injector)
        mod._diftw_dependencies = dependencies
      }
    end
  end
end
