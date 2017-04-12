require File.expand_path('../test_helper', __FILE__)

class TestAuthToken < Minitest::Test
  FIXTURE = API_FIXTURES.fetch(:authorization)
  def auth_uri_stub
    "#{prefix_for_all_requests}#{FieldView.oauth_token_base[8..-1]}"
  end

  def check_token_matches_fixture(token)
    assert_equal FIXTURE[:access_token], token.access_token
    assert_equal FIXTURE[:refresh_token], token.refresh_token
    assert_equal FieldView.now + FIXTURE[:expires_in] - 15, token.access_token_expiration_at
    assert_equal FieldView.now - 5 + 29*24*60*60, token.refresh_token_expiration_at, "Should be 29 days in the future"
  end

  def setup
    setup_for_api_requests
  end
  
  def teardown
    teardown_for_api_request
  end

  def test_build_token_request
    http, request = FieldView::AuthToken.build_token_request([["dont", "care"]])
    assert_equal "/api/oauth/token?dont=care", request.path

    headers = request.to_hash
    assert_equal ["*/*"], headers["accept"]
    assert_equal ["Basic #{Base64.encode64("#{FieldView.client_id}:#{FieldView.client_secret}").strip}"], headers["authorization"]
    assert_equal ["application/x-www-form-urlencoded"], headers["content-type"]

    assert_equal Net::HTTP::Post, request.class
    assert_equal "api.climate.com", http.address
  end

  def test_new_auth_token_with_code_from_redirect_code_bad
    stub_request(:post, "#{auth_uri_stub}?" \
      "code&grant_type=authorization_code&redirect_uri=#{FieldView.redirect_uri}").
        to_return(status: 401, body: JSON.generate({}))
    assert_raises FieldView::AuthenticationError do
      FieldView::AuthToken.new_auth_token_with_code_from_redirect_code(nil)
    end
  end

  def test_new_auth_token_with_code_from_redirect_code_good
    # now a good token
    code = "code"
    FieldView.now = Time.now
    stub_request(:post, "#{auth_uri_stub}?" \
      "code=#{code}&grant_type=authorization_code&redirect_uri=#{FieldView.redirect_uri}").
        to_return(status: 200, body: JSON.generate(FIXTURE))
    token = FieldView::AuthToken.new_auth_token_with_code_from_redirect_code(code)
    check_token_matches_fixture(token)
  end

  def test_create_with_just_access_token
    token = FieldView::AuthToken.new(access_token: "yyy")
    assert !token.access_token_expired?
    assert token.refresh_token_expired?
  end

  def test_create_with_just_refresh_token
    FieldView.now = Time.now
    token = FieldView::AuthToken.new(refresh_token: "xxx")
    assert token.access_token_expired?
    assert !token.refresh_token_expired?

    stub_request(:post, "#{auth_uri_stub}?" \
      "grant_type=refresh_token&refresh_token=#{token.refresh_token}").
      to_return(status: 200, body: JSON.generate(FIXTURE))
    token.refresh_access_token!
    check_token_matches_fixture(token)
  end

  def test_completely_expired_token
    token = FieldView::AuthToken.new(
      access_token: "yyy",
      refresh_token: "xxx",
      refresh_token_expiration_at: Time.now - 20,
      access_token_expiration_at: Time.now - 20
      )

    assert token.access_token_expired?
    assert token.refresh_token_expired?

    assert_raises FieldView::AllTokensExpiredError do
      token.execute_request(:get, "dont/care")
    end
  end
end