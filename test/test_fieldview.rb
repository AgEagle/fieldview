require File.expand_path('../test_helper', __FILE__)

class FieldViewTest < Minitest::Test
  def test_now
    assert (Time.now - FieldView.get_now_for_auth_token) <= 5, "should be close"
    expected_time = Time.now - 20
    FieldView.now = expected_time
    assert_equal expected_time, FieldView.get_now_for_auth_token
  end

  def test_requires_client_id
    FieldView.client_id = nil
    assert_raises FieldView::AuthenticationError do
      FieldView.client_id
    end
    FieldView.client_id = "test"
    assert FieldView.client_id
  end

  def test_requires_client_secret
    FieldView.client_secret = nil
    assert_raises FieldView::AuthenticationError do
      FieldView.client_secret
    end
    FieldView.client_secret = "test"
    assert FieldView.client_secret
  end

  def test_requires_redirect_uri
    FieldView.redirect_uri = nil
    assert_raises FieldView::AuthenticationError do
      FieldView.redirect_uri
    end
    FieldView.redirect_uri = "test"
    assert FieldView.redirect_uri
  end

  def test_requires_x_api_key
    FieldView.x_api_key = nil
    assert_raises FieldView::AuthenticationError do
      FieldView.x_api_key
    end
    FieldView.x_api_key = "test"
    assert FieldView.x_api_key
  end
end