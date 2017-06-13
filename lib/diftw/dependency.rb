module DiFtw
  #
  # Class representing an injected dependency.
  #
  class Dependency
    # @return [Proc] proc that returns the dependency
    attr_reader :y
    # @return [Boolean] whether or not this depdency is a singleton
    attr_reader :singleton
    # @return [Mutex] the mutex for accessing the Singleton
    attr_reader :mutex

    #
    # A new dependency.
    #
    # @param y [Proc] returns the dependency
    # @param singleton [Boolean] if true, the Proc will only be called the first time the dep is injected.
    #
    def initialize(y, singleton:)
      @y = y
      @singleton = singleton
      @mutex = Mutex.new if singleton
    end

    #
    # Return the value for the dependency. If this is a singleton, the value will
    # only be initialized on the first call (thread safe). Otherwise, the proc will
    # called each time.
    #
    def resolve
      if singleton
        @val || mutex.synchronize { @val ||= y.() }
      else
        y.()
      end
    end
  end
end
