require File.expand_path('../test_helper', __FILE__)

class TestListObject < Minitest::Test
  FIXTURE = API_FIXTURES.fetch(:single_field_list)

  def test_each_loop
    data = ["x","y","z"]
    list = FieldView::ListObject.new(FieldView::Fields, new_auth_token, data, 200, next_token: nil)

    list.each_with_index do |x, i|
      assert_equal data[i], x
    end
  end

  def test_get_next_page
    next_token = "JZIOJKLJ"
    list = FieldView::ListObject.new(FieldView::Fields, new_auth_token, 
      ["dont","care"], 206, next_token: next_token)
    stub_request(:get, /fields/).
      with(headers: next_token_headers(next_token)).
      to_return(status: 200, body: API_FIXTURES[:field_two_list].to_json(),
        headers: next_token_headers())

    api_requests() do
      list.next_page!()
    end

    assert_equal 1, list.data.length
    assert_equal  API_FIXTURES[:field_two_list][:results][0][:id], list.data[0].id
    assert !list.more_pages?()
  end
end