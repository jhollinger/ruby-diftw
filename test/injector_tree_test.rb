require_relative './test_helper'

class InjectorTreeTest < Minitest::Test
  def setup
    @injector = DiFtw::Injector.new
    @injector[:foo] = -> { OpenStruct.new(message: 'Foo') }
  end

  def test_injector_builds_children
    di = @injector
    klass_x = Class.new {
      include di.inject(:foo)
    }
    klass_y = Class.new {
      include di.inject(:foo)
    }

    x1, x2 = klass_x.new, klass_x.new
    y1, y2 = klass_y.new, klass_y.new

    refute_equal @injector.object_id, klass_x.injector.object_id
    refute_equal @injector.object_id, klass_y.injector.object_id
    refute_equal klass_x.injector.object_id, klass_y.injector.object_id

    refute_equal klass_x.injector.object_id, x1.injector.object_id

    refute_equal x1.injector.object_id, x2.injector.object_id
    refute_equal y1.injector.object_id, y2.injector.object_id
    refute_equal x1.injector.object_id, y1.injector.object_id
    refute_equal x2.injector.object_id, y2.injector.object_id

    assert_equal x1.class.injector.object_id, x2.class.injector.object_id
    assert_equal x1.class.injector.object_id, x1.injector.send(:parent).object_id
  end

  def test_instance_injector_builds_children
    x = OpenStruct.new
    @injector.inject_instance x, :foo
    refute_equal @injector.object_id, x.injector.object_id
    assert_equal @injector.object_id, x.singleton_class.injector.send(:parent).object_id
    assert_equal x.singleton_class.injector.object_id, x.injector.send(:parent).object_id
  end

  def test_child_singleton_finds_parent_dep
    di = @injector
    klass = Class.new {
      include di.inject(:foo)
    }
    x = klass.new
    assert_equal di[:foo].object_id, klass.injector[:foo].object_id
    assert_equal klass.injector[:foo].object_id, x.foo.object_id
  end

  def test_reinject_into_child_doesnt_effect_parents_even_when_parent_hasnt_been_accessed
    di = @injector
    klass = Class.new {
      include di.inject(:foo)
    }
    x = klass.new
    x.injector[:foo] = -> { OpenStruct.new(message: 'Foo!!1!') }
    assert_equal 'Foo!!1!', x.foo.message
    assert_equal 'Foo', klass.injector[:foo].message
    assert_equal 'Foo', di[:foo].message
  end

  def test_reinject_into_child_doesnt_effect_parents_when_parent_has_been_accessed
    di = @injector
    klass = Class.new {
      include di.inject(:foo)
    }
    x = klass.new
    assert_equal 'Foo', klass.injector[:foo].message
    assert_equal 'Foo', di[:foo].message

    x.injector[:foo] = -> { OpenStruct.new(message: 'Foo!!1!') }
    assert_equal 'Foo!!1!', x.foo.message
    assert_equal 'Foo', klass.injector[:foo].message
    assert_equal 'Foo', di[:foo].message
  end

  def test_reinject_into_parent_doesnt_effect_children_when_children_have_already_been_accessed
    di = @injector
    klass = Class.new {
      include di.inject(:foo)
    }
    x = klass.new
    assert_equal 'Foo', x.foo.message

    di[:foo] = -> { OpenStruct.new(message: 'Foo!!1!') }
    assert_equal 'Foo!!1!', di[:foo].message
    assert_equal 'Foo', klass.injector[:foo].message
    assert_equal 'Foo', x.foo.message
  end

  def test_reinject_into_parent_does_have_effect_before_children_have_been_accessed
    di = @injector
    klass = Class.new {
      include di.inject(:foo)
    }
    x = klass.new
    di[:foo] = -> { OpenStruct.new(message: 'Foo!!1!') }
    assert_equal 'Foo!!1!', x.foo.message
  end
end
