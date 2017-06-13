require_relative './test_helper'

class ExtendTest < Minitest::Test
  def setup
    @injector = DiFtw::Injector.new
    @injector.singleton(:foo) { OpenStruct.new(message: 'Foo') }
  end

  def test_class_extending
    klass = Class.new
    klass.send(:extend, @injector.inject(:foo))
    assert klass.respond_to?(:foo)
    assert_equal 'Foo', klass.foo.message
    refute_equal @injector.object_id, klass.injector.object_id
    refute klass.new.respond_to?(:foo)
  end

  def test_class_extending_and_overriding
    klass = Class.new
    klass.send(:extend, @injector.inject(:foo))
    klass.injector.singleton(:foo) { OpenStruct.new(message: 'Bar') }
    assert_equal 'Bar', klass.foo.message
  end

  def test_module_extending
    mod = Module.new
    mod.send(:extend, @injector.inject(:foo))
    assert mod.respond_to?(:foo)
    assert_equal 'Foo', mod.foo.message
    refute_equal @injector.object_id, mod.injector.object_id
  end

  def test_module_extending_doesnt_extend_instances
    mod = Module.new
    mod.send(:extend, @injector.inject(:foo))
    klass = Class.new { include mod }
    refute klass.new.respond_to?(:foo)
  end

  def test_module_extending_and_overriding
    mod = Module.new
    mod.send(:extend, @injector.inject(:foo))
    mod.injector.singleton(:foo) { OpenStruct.new(message: 'Bar') }
    assert_equal 'Bar', mod.foo.message
  end
end
