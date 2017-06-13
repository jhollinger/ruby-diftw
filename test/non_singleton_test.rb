require_relative './test_helper'

class NonSingletonTest < Minitest::Test
  def setup
    @injector = DiFtw::Injector.new
    @injector.register(:foo) { OpenStruct.new(message: 'Foo') }
  end

  def test_different_object_each_call
    id1, id2 = @injector[:foo].object_id, @injector[:foo].object_id
    refute_equal id1, id2
  end
end
