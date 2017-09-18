module DiFtw
  #
  # A dependency that will be re-created every time it's injected.
  #
  class Factory
    #
    # A new dependency.
    #
    # @param y [Proc] returns the dependency
    #
    def initialize(y)
      @y = y
      @val = nil
    end

    #
    # Return the value for the dependency by calling the registration Proc.
    #
    def resolve
      @y.call
    end
  end
end
