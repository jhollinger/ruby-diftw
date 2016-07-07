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

  def test_lazy_registration
    @injector[:ab] = -> { @injector[:a] + @injector[:b] }
    @injector[:a] = -> { 'A' }
    @injector[:b] = -> { 'B' }
    klass = Class.new
    klass.send(:include, @injector.inject(:ab))
    assert_equal 'AB', klass.new.ab
  end

  def test_lazy_injection
    klass = Class.new
    klass.send(:include, @injector.inject(:foo))
    x = klass.new
    assert_nil x.instance_variable_get('@_diftw_foo')
    x.foo
    refute_nil x.instance_variable_get('@_diftw_foo')
  end

  def test_eager_injection
    klass = Class.new {
      def initialize
        inject!
      end
    }
    klass.send(:include, @injector.inject(:foo))
    x = klass.new
    refute_nil x.instance_variable_get('@_diftw_foo')
  end
end
