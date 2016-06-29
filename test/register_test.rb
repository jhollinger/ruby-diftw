require_relative './test_helper'

class RegisterTest < Minitest::Test
  def setup
    @injector = DiFtw::Injector.new
  end

  def test_register_during_initialize
    injector = DiFtw::Injector.new do
      register :foo do
        OpenStruct.new(message: 'Foo')
      end
    end
    assert_equal 'Foo', injector[:foo].message
  end

  def test_register_after_initialize
    @injector.register :foo do
      OpenStruct.new(message: 'Foo')
    end
    assert_equal 'Foo', @injector[:foo].message
  end

  def test_register_alt_syntax
    @injector[:foo] = -> { OpenStruct.new(message: 'Foo') }
    assert_equal 'Foo', @injector[:foo].message
  end

  def test_new_proc_call_each_time
    @injector[:foo] = -> { OpenStruct.new(message: 'Foo') }
    id1, id2 = @injector[:foo].object_id, @injector[:foo].object_id
    refute_equal id1, id2
  end
end
