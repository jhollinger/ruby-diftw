module DiFtw
  #
  # Class that provides a dependency via a "call" method. It may optionally depend on other dependencies,
  # which will be available as methods inside the given Proc.
  #
  class Provider
    #
    # @param injector [DiFtw::Injection]
    # @param name [Symbol]
    # @param y [Proc]
    # @param deps [Array<Symbol]
    #
    def initialize(injector, name, y, deps = [])
      @name, @y = name, y
      injector.inject_instance self, *deps if deps.any?
    end

    # Executes the proc and returns the dependency
    def call
      self.instance_exec(&@y)
    end
  end
end
