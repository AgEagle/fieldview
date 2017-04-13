require File.expand_path('../test_helper', __FILE__)

class TestFields < Minitest::Test
  FIXTURE = API_FIXTURES.fetch(:single_field_list)

  def setup
    setup_for_api_requests
  end
  
  def teardown
    teardown_for_api_request
  end
  
  def test_list_with_one_page()
    next_token = "AZXJKLA123"
    stub_request(:get, /fields/).
      with(headers: { FieldView::PAGE_LIMIT_HEADER_KEY => FieldView.default_page_limit.to_s}).
      to_return(status: 200, body: FIXTURE.to_json(),
        headers: next_token_headers)
    fields = FieldView::Fields.list(new_auth_token)

    assert_equal FIXTURE[:results].length, fields.data.length
    assert_equal FIXTURE[:results][0][:id], fields.data[0].id
    assert_equal next_token, fields.next_token
    assert_equal FieldView::Fields, fields.listable
  end

  def test_list_with_no_more_data
    stub_request(:get, /fields/).
      with(headers: { FieldView::PAGE_LIMIT_HEADER_KEY => FieldView.default_page_limit.to_s}).
      to_return(status: 304, body: {}.to_json(),
        headers: next_token_headers)
    fields = FieldView::Fields.list(new_auth_token)

    assert_equal 0, fields.data.length
  end

  def test_with_more_data
    next_token = "AZXJKLA123"
    stub_request(:get, /fields/).
      with(headers: { FieldView::PAGE_LIMIT_HEADER_KEY => FieldView.default_page_limit.to_s}).
      to_return(status: 200, body: FIXTURE.to_json(),
        headers: next_token_headers)
    fields = FieldView::Fields.list(new_auth_token)

    assert_equal FIXTURE[:results].length, fields.data.length
    assert_equal FIXTURE[:results][0][:id], fields.data[0].id
    assert_equal next_token, fields.next_token
  end

  def test_with_limit
    stub_request(:get, /fields/).
      with(headers: { FieldView::PAGE_LIMIT_HEADER_KEY => 1}).
      to_return(status: 200, body: FIXTURE.to_json(),
        headers: next_token_headers)
    fields = FieldView::Fields.list(new_auth_token, limit: 1)

    assert_equal 1, fields.data.length
  end

  def test_with_next_token
    next_token = "AZXJKLA123"
    stub_request(:get, /fields/).
      with(headers: { FieldView::NEXT_TOKEN_HEADER_KEY => next_token }).
      to_return(status: 200, body: FIXTURE.to_json())

    fields = FieldView::Fields.list(new_auth_token, next_token: next_token)
    assert_equal 1, fields.data.length
  end
end