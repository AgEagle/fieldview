require File.expand_path('../test_helper', __FILE__)

class TestField < Minitest::Test
  FIXTURE = API_FIXTURES.fetch(:single_field_list)[:results][0]
  def test_initialization
    field = FieldView::Field.new(FIXTURE, new_auth_token)
  
    assert_equal FIXTURE[:id], field.id
    assert_equal FIXTURE[:name], field.name
    assert_equal FIXTURE[:boundaryId], field.boundary_id
    assert_equal new_auth_token.access_token, field.auth_token.access_token
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