require File.expand_path('../test_helper', __FILE__)

class TestListObject < Minitest::Test

  def test_each_loop
    data = ["x","y","z"]
    list = FieldView::ListObject.new(new_auth_token, data, 200, next_token: nil)

    list.each_with_index do |x, i|
      assert_equal data[i], x
    end
  end

  def test_get_next_page

  end
end