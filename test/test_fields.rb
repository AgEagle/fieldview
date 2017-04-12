require File.expand_path('../test_helper', __FILE__)

class TestFields < Minitest::Test
  FIXTURE = API_FIXTURES.fetch(:single_field_list)

  def next_token_headers(next_token = "AZXJKLA123")
    {FieldView::NEXT_TOKEN_HEADER_KEY => next_token}
  end

  def setup
    setup_for_api_requests
  end
  
  def teardown
    teardown_for_api_request
  end
  
  def test_list_with_one_page()
    next_token = "AZXJKLA123"
    stub_request(:get, "https://platform.climate.com/v4/fields").
      with(headers: hash_including({
          FieldView::PAGE_LIMIT_HEADER_KEY => FieldView.default_page_limit.to_s
      })).
      to_return(status: 200, body: JSON.generate(FIXTURE),
        headers: next_token_headers)
    fields = FieldView::Fields.list(new_auth_token)

    assert_equal FIXTURE[:results].length, fields.data.length
    assert_equal FIXTURE[:results][0][:id], fields.data[0].id
    assert_equal next_token, fields.next_token
  end

  def test_list_with_no_more_data
    stub_request(:get, "https://platform.climate.com/v4/fields").
      with(headers: hash_including({
          FieldView::PAGE_LIMIT_HEADER_KEY => FieldView.default_page_limit.to_s
      })).
      to_return(status: 304, body: JSON.generate({}),
        headers: next_token_headers)
    fields = FieldView::Fields.list(new_auth_token)

    assert_equal 0, fields.data.length
  end

  def test_with_next_token
  end

  def test_with_more_data
    next_token = "AZXJKLA123"
    stub_request(:get, "https://platform.climate.com/v4/fields").
      with(headers: hash_including({
          FieldView::PAGE_LIMIT_HEADER_KEY => FieldView.default_page_limit.to_s
      })).
      to_return(status: 200, body: JSON.generate(FIXTURE),
        headers: next_token_headers)
    fields = FieldView::Fields.list(new_auth_token)

    assert_equal FIXTURE[:results].length, fields.data.length
    assert_equal FIXTURE[:results][0][:id], fields.data[0].id
    assert_equal next_token, fields.next_token
  end
end