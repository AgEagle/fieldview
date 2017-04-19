require 'net/http'
require 'json'
require 'rbconfig'
require 'base64'

# API Support Classes
require 'fieldview/errors'
require 'fieldview/requestable'
require 'fieldview/auth_token'
require 'fieldview/fields'
require 'fieldview/util'
require 'fieldview/fieldview_response'
require 'fieldview/field'
require 'fieldview/upload'
require 'fieldview/list_object'
require 'fieldview/boundary'

module FieldView
  @oauth_token_base = "https://api.climate.com/api/oauth/token"
  @api_base = "https://platform.climate.com/v"
  @max_network_retries = 0
  @api_version = 4
  @default_page_limit = 100
  NEXT_TOKEN_HEADER_KEY = "X-Next-Token"
  REQUEST_ID_HEADER_KEY = "X-Http-Request-Id"
  PAGE_LIMIT_HEADER_KEY = "X-Limit"

  class << self
    attr_accessor :oauth_token_base, :api_base, :max_network_retries, :api_version, :now,
      :default_page_limit

    def get_now_for_auth_token
      now || Time.now
    end

    def x_api_key
      @_x_api_key ||= nil
      unless @_x_api_key
        raise AuthenticationError.new('No x-api-key provided. ' \
          'Set your x-api-key using "FieldView.x_api_key = <X-API-KEY>". ' \
          'This should have been provided to you by a Climate representative. ' \
          'This takes the form of "my-client"')
      end
      return @_x_api_key
    end
    def x_api_key=(value)
      @_x_api_key = value
    end

    def redirect_uri
      @_redirect_uri ||= nil
      unless @_redirect_uri
        raise AuthenticationError.new("You must set the redirect uri to your proper server " \
          "to get new auth tokens if you haven't set one. " \
          "Set your redirect uri using FieldView.redirect_uri = <REDIRECT_URI>")
      end
      return @_redirect_uri
    end
    def redirect_uri=(value)
      @_redirect_uri = value
    end

    def client_id
      @_client_id ||= nil
      unless @_client_id
        raise AuthenticationError.new('No client id provided. ' \
          'Set your client id using "FieldView.client_id = <CLIENT-ID>". ' \
          'This should have been provided to you by a Climate representative. ' \
          'This takes the form of "my-client"')
      end
      return @_client_id
    end
    def client_id=(value)
      @_client_id = value
    end

    def client_secret
      @_client_secret ||= nil
      unless @_client_secret
        raise AuthenticationError.new('No client_secret provided. ' \
          'Set your client secret using "FieldView.client_secret = <CLIENT-SECRET>". ' \
          'This should have been provided to you by a Climate representative. ' \
          'This takes the form of "my-client-fz9900x98-x98908j-jslx"')
      end
      return @_client_secret
    end
    def client_secret=(value)
      @_client_secret = value
    end

    def handle_response_error_codes(response)
      headers = response.to_hash
      code = response.code.to_i
      body = response.body
      error = nil
      case code
      when 503
        error = ServerBusyError.new(
          "Server Busy", http_status: code, http_body: body,
          http_headers: headers)
      when 400, 404
        error = InvalidRequestError.new(
          "Bad input", http_status: code, http_body: body,
          http_headers: headers)
      when 401
        error = AuthenticationError.new(
          "Unauthorized", http_status: code, http_body: body,
          http_headers: headers)
      when 403
        error = PermissionError.new(
          "Forbidden", http_status: code, http_body: body,
          http_headers: headers)
      when 429
        # Retry-After will be in the headers
        error = RateLimitError.new(
          "Too many requests", http_status: code, http_body: body,
          http_headers: headers)
      when 500
        error = InternalServerError.new(
          "Internal server error", http_status: code, http_body: body,
          http_headers: headers)
      end
        
      if error.nil? then
        return
      else
        error.response = response
        raise error
      end
    end
  end
end