require_relative './test_helper'

class RegisterTest < Minitest::Test
  def setup
    @injector = DiFtw::Injector.new
  end

  def test_singleton_during_initialize
    injector = DiFtw::Injector.new do
      singleton :foo do
        OpenStruct.new(message: 'Foo')
      end
    end
    assert_equal 'Foo', injector[:foo].message
  end

  def test_singleton_after_initialize
    @injector.singleton :foo do
      OpenStruct.new(message: 'Foo')
    end
    assert_equal 'Foo', @injector[:foo].message
  end

  def test_singleton
    @injector.singleton(:foo) { OpenStruct.new(message: 'Foo') }
    id1, id2 = @injector[:foo].object_id, @injector[:foo].object_id
    assert_equal id1, id2
  end
end
