# class FieldViewToken < ActiveRecord::Base
#   OAUTH_TOKEN_URI = "https://api.climate.com/api/oauth/token"
#   belongs_to :user

#   validates_presence_of(:access_token, :refresh_token, 
#     :access_token_expiration_at, :refresh_token_expiration_at,
#     :user)

  
#   def self.new_from_code(code, redirect_uri, user)
#     http, request = build_token_request([
#       ["grant_type", "authorization_code"],
#       ["redirect_uri", redirect_uri],
#       ["code", code]
#     ])
#     logger.info("[#{Time.now}] Starting request for ClimateView oauth token: #{request.path}")
#     now = Time.now
#     response = http.request(request)
#     logger.info("[#{Time.now}] Finished request for ClimateView oauth token: #{response.body}")
#     if response.code != "200" then
#       # An error has occurred, log to roll bar and notify them
#       logger.error("Failed to acquire field view token, response body: #{response.body}")
#       return new
#     else
#       json = JSON.parse(response.body)
#       return new(
#         access_token: json["access_token"],
#         refresh_token: json["refresh_token"],
#         # Assume the average request will take some time
#         access_token_expiration_at: now + json["expires_in"] - 10,
#         # Technically it's one month, but give us the benefit of the doubt
#         refresh_token_expiration_at: Time.now + 29.days,
#         user: user
#       )
#     end
#   end

#   def refresh_access_token!()
#     http, request = self.class.build_token_request([
#       ["grant_type", "refresh_token"],
#       ["refresh_token", self.refresh_token]
#     ])
#     now = Time.now
#     response = http.request(request)
#     if response.code != "200" then
#       # An error has occurred, log to roll bar and notify them
#       raise "Failed to refresh field view token, response body: #{response.body}"
#     else
#       json = JSON.parse(response.body)
#       self.update!(
#         access_token: json["access_token"],
#         # Assume the average request will take some time
#         access_token_expiration_at: now + json["expires_in"] - 10,
#         refresh_token: json["refresh_token"],
#         refresh_token_expiration_at: now + 29.days
#       )
#     end
#   end

#   # This is how the access token should be acquired as 
#   # getting the raw access token it may be expired
#   def get_access_token()
#     if access_token_expired? then
#       refresh_access_token!()
#     end
#     return self.access_token
#   end

#   REQUEST_URI = "https://platform.climate.com/v4/"

#   def get_fields_and_boundaries()
#     response = request_against_access_token(Net::HTTP::Get, "fields")
#     headers = response.to_hash
#     if headers["x-next-token"].present? then
#       # TODO: Record it so that we can optimize requests in the future
#       # response code of 206 will be returned if more
#       # X-Http-Request-Id might be a useful thing to create in the database
#     end
#     case response.code
#     when "304"
#       # we're done, will it return a next-token?
#       return
#     when "206"
#       # we have more to get
#     when "200"
#       return
#     end
#   end

#   def request_against_access_token(method, path, headers = {})
#     uri = URI.parse("#{REQUEST_URI}#{path}")
#     http = Net::HTTP.new(uri.host, uri.port)
#     http.use_ssl = true
#     request = method.new(uri.request_uri)
#     request["User-Agent"] = "FarmLens"
#     request["Accept"] = "*/*"
#     request["Authorization"] = "Bearer #{self.get_access_token()}"
#     request["X-Api-Key"] = APP_CONFIG['field_view_x_api_key']
#     request["Content-Type"] = "application/json"
#     headers.each do |header,value|
#       request[header] = value
#     end
#     return http.request(request)
#   end

#   def access_token_expired?()
#     return self.access_token_expiration_at <= Time.now
#   end

#   def refresh_token_expired?()
#     return self.refresh_token_expiration_at <= Time.now
#   end
# end
require 'net/http'
require 'json'
require 'rbconfig'
require 'base64'

# API Support Classes
require 'fieldview/errors'
require 'fieldview/auth_token'
require 'fieldview/fields'
require 'fieldview/fieldview_response'
require 'fieldview/field'

module FieldView
  @oauth_token_base = "https://api.climate.com/api/oauth/token"
  @api_base = "https://platform.climate.com/v"
  @max_network_retries = 0
  @api_version = 4
  NEXT_TOKEN_HEADER_KEY = "X-Next-Token"
  REQUEST_ID_HEADER_KEY = "X-Http-Request-Id"

  class << self
    attr_accessor :oauth_token_base, :api_base, :max_network_retries, :api_version, :now

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

    def handle_response_error_codes!(response)
      headers = response.to_hash
      code = response.code.to_i
      body = response.body
      error = nil
      case code
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