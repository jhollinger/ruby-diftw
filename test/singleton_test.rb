require_relative './test_helper'

class SingletonTest < Minitest::Test
  def setup
    @injector = DiFtw::Injector.new(singleton: true)
    @injector[:foo] = -> { OpenStruct.new(message: 'Foo') }
  end

  def test_same_object_each_call
    id1, id2 = @injector[:foo].object_id, @injector[:foo].object_id
    assert_equal id1, id2
  end
end
