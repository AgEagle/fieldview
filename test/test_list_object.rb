require File.expand_path('../test_helper', __FILE__)

class TestListObject < Minitest::Test
  FIXTURE = API_FIXTURES.fetch(:single_field_list)
  
  def setup
    setup_for_api_requests
  end
  
  def teardown
    teardown_for_api_request
  end
  
  def test_each_loop
    data = ["x","y","z"]
    list = FieldView::ListObject.new(FieldView::Field, new_auth_token, data, 200, next_token: nil)

    list.each_with_index do |x, i|
      assert_equal data[i], x
    end
  end

  def test_restart
    next_token = "JZIOJKLJ"
    old_next_token = "DONTCARE"
    list = FieldView::ListObject.new(FieldView::Field, new_auth_token, 
      ["dont","care"], 206, next_token: old_next_token)
    stub_request(:get, /fields/).
      to_return(status: 200, body: API_FIXTURES[:field_two_list].to_json(),
        headers: next_token_headers(next_token))
    
    list.restart!
    
    assert_equal list.next_token, next_token
    assert_equal list.last_http_status, 200
    assert_equal API_FIXTURES[:field_two_list][:results][0][:id], list.data[0].id
  end

  def test_get_next_page
    next_token = "JZIOJKLJ"
    list = FieldView::ListObject.new(FieldView::Field, new_auth_token, 
      ["dont","care"], 206, next_token: next_token)
    stub_request(:get, /fields/).
      with(headers: next_token_headers(next_token)).
      to_return(status: 200, body: API_FIXTURES[:field_two_list].to_json(),
        headers: next_token_headers())

    api_requests() do
      list.next_page!()
    end

    assert_equal 1, list.data.length
    assert_equal API_FIXTURES[:field_two_list][:results][0][:id], list.data[0].id
    assert !list.more_pages?()
  end
end