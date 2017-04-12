require 'minitest/autorun'
require 'fieldview'
require 'byebug'
require 'webmock/minitest'

PROJECT_ROOT = File.expand_path("../../", __FILE__)
require File.expand_path('../api_fixtures', __FILE__)

class Minitest::Test
  # Fixtures are available in tests using something like:
  #
  #   API_FIXTURES[:charge][:id]
  #
  API_FIXTURES = APIFixtures.new

  def setup_for_api_requests()
    FieldView.redirect_uri = "http://fake.test/"  
    FieldView.client_id = "fake-client"
    FieldView.client_secret = "fake-client-abcdef12-3456-7890-abcd-ef0123456789"
    FieldView.x_api_key = "ixj98c98njkn109su9jxkjks61"
  end

  def teardown_for_api_request()
    FieldView.redirect_uri = nil
    FieldView.client_id = nil
    FieldView.client_secret = nil
    FieldView.x_api_key = nil
    FieldView.now = nil
  end

  def prefix_for_all_requests
    "https://#{FieldView.client_id}:#{FieldView.client_secret}@"
  end
end