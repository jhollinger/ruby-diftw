require_relative './test_helper'

class InstanceInjectorTest < Minitest::Test
  def setup
    @injector = DiFtw::Injector.new
    @injector.singleton(:foo) { OpenStruct.new(message: 'Foo') }
  end

  def test_instance_injector
    klass = Class.new
    x = klass.new
    refute x.respond_to?(:foo)
    @injector.inject_instance x, :foo
    assert x.respond_to?(:foo)
    assert_equal 'Foo', x.foo.message
    refute klass.new.respond_to?(:foo)
  end
end
