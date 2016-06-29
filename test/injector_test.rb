require_relative './test_helper'

class InjectorTest < Minitest::Test
  def setup
    @injector = DiFtw::Injector.new
    @injector[:foo] = -> { OpenStruct.new(message: 'Foo') }
    @injector[:bar] = -> { OpenStruct.new(message: 'Bar') }
    @injector[:baz] = -> { OpenStruct.new(message: 'Baz') }
  end

  def test_injector
    klass = Class.new
    klass.send(:include, @injector.inject(:foo, :bar))
    x = klass.new
    assert_equal 'Foo', x.foo.message
    assert_equal 'Bar', x.bar.message
    assert x.respond_to?(:foo)
    assert x.respond_to?(:bar)
    refute x.respond_to?(:baz)
  end
end
