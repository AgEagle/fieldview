require File.expand_path('../test_helper', __FILE__)

class TestField < Minitest::Test
  FIXTURE = API_FIXTURES.fetch(:single_field_list)[:results][0]
  LIST_FIXTURE = API_FIXTURES.fetch(:single_field_list)

  def setup
    setup_for_api_requests
  end
  
  def teardown
    teardown_for_api_request
  end

  def test_retrieve()
    stub_request(:get, /fields/).
      to_return(status: 200, body: FIXTURE.to_json)

    field = FieldView::Field.retrieve(new_auth_token, FIXTURE[:id])

    assert_equal FIXTURE[:id], field.id
    assert_equal FIXTURE[:name], field.name
    assert_equal FIXTURE[:boundaryId], field.boundary_id
    assert_equal new_auth_token.access_token, field.auth_token.access_token
  end

  def test_list_with_bad_status()
    stub_request(:get, /fields/).
      to_return(status: 207)

    assert_raises FieldView::UnexpectedResponseError do
      field = FieldView::Field.list(new_auth_token)
    end
  end
  
  def test_list_with_one_page()
    next_token = "AZXJKLA123"
    stub_request(:get, /fields/).
      with(headers: { FieldView::PAGE_LIMIT_HEADER_KEY => FieldView.default_page_limit.to_s}).
      to_return(status: 200, body: LIST_FIXTURE.to_json(),
        headers: next_token_headers)
    fields = FieldView::Field.list(new_auth_token)

    assert_equal LIST_FIXTURE[:results].length, fields.data.length
    assert_equal LIST_FIXTURE[:results][0][:id], fields.data[0].id
    assert_equal next_token, fields.next_token
    assert_equal FieldView::Field, fields.listable
  end

  def test_list_with_no_more_data
    stub_request(:get, /fields/).
      with(headers: { FieldView::PAGE_LIMIT_HEADER_KEY => FieldView.default_page_limit.to_s}).
      to_return(status: 304, body: {}.to_json(),
        headers: next_token_headers)
    fields = FieldView::Field.list(new_auth_token)

    assert_equal 0, fields.data.length
  end

  def test_with_more_data
    next_token = "AZXJKLA123"
    stub_request(:get, /fields/).
      with(headers: { FieldView::PAGE_LIMIT_HEADER_KEY => FieldView.default_page_limit.to_s}).
      to_return(status: 200, body: LIST_FIXTURE.to_json(),
        headers: next_token_headers)
    fields = FieldView::Field.list(new_auth_token)

    assert_equal LIST_FIXTURE[:results].length, fields.data.length
    assert_equal LIST_FIXTURE[:results][0][:id], fields.data[0].id
    assert_equal next_token, fields.next_token
  end

  def test_with_limit
    stub_request(:get, /fields/).
      with(headers: { FieldView::PAGE_LIMIT_HEADER_KEY => 1}).
      to_return(status: 200, body: LIST_FIXTURE.to_json(),
        headers: next_token_headers)
    fields = FieldView::Field.list(new_auth_token, limit: 1)

    assert_equal 1, fields.data.length
  end

  def test_with_next_token
    next_token = "AZXJKLA123"
    stub_request(:get, /fields/).
      with(headers: { FieldView::NEXT_TOKEN_HEADER_KEY => next_token }).
      to_return(status: 200, body: LIST_FIXTURE.to_json())

    fields = FieldView::Field.list(new_auth_token, next_token: next_token)
    assert_equal 1, fields.data.length
  end
  
  def test_get_boundary
    field = FieldView::Field.new(FIXTURE, new_auth_token)

    stub_request(:get, /boundaries\/#{API_FIXTURES[:boundary_one][:id]}/).
      to_return(status: 200, body: API_FIXTURES[:boundary_one].to_json())

    api_requests() do
      field.boundary
    end

    assert_equal FIXTURE[:boundaryId], field.boundary.id
  end
end