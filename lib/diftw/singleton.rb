module DiFtw
  #
  # Class representing an injected dependency that's only created once.
  #
  class Singleton
    #
    # A new dependency.
    #
    # @param y [Proc] returns the dependency
    #
    def initialize(y)
      @y = y
      @val = nil
      @mutex = Mutex.new
    end

    #
    # Return the value for the dependency. If this is the first access, the injected value
    # will be cached and re-used for later injections. Yes, it's thread-safe.
    #
    def resolve
      @val || @mutex.synchronize { @val ||= @y.() }
    end
  end
end
