module FieldView
  class AuthToken
    attr_accessor :access_token, :access_token_expiration_at, :refresh_token, :refresh_token_expiration_at
    attr_accessor :last_request
    attr_accessor :last_request_headers
    def initialize(params)
      # Assume now was 5 seconds ago
      now = FieldView.get_now_for_auth_token - 5

      # Used on every request
      self.access_token = params[:access_token]

      # When the access token expires we'll need to refresh,
      # can be specified as part of the object, 14399 is what is being
      # returned at the time of writing this (2017-04-11)
      if params[:access_token_expiration_at].is_a?(String) then
        self.access_token_expiration_at = Time.parse(params[:access_token_expiration_at])
      else
        self.access_token_expiration_at =  params[:access_token_expiration_at] || (now + (params[:expires_in]||14399))
      end

      # Refresh token isn't required, but can be initialized with this
      self.refresh_token = params[:refresh_token]

      # Refresh token technically expires in 30 days
      if params[:refresh_token_expiration_at].is_a?(String) then
        self.refresh_token_expiration_at = Time.parse(params[:refresh_token_expiration_at])
      else
        self.refresh_token_expiration_at =  params[:refresh_token_expiration_at] || (now + (30)*24*60*60)
      end
    end

    def access_token_expired?
      return !!(self.access_token.nil? || self.access_token_expiration_at <= Time.now)
    end

    def refresh_token_expired?
      return !!(self.refresh_token.nil? || self.refresh_token_expiration_at <= Time.now)
    end

    def refresh_access_token!()
      http, request = self.class.build_token_request([
        ["grant_type", "refresh_token"],
        ["refresh_token", self.refresh_token]
      ])
      response = http.request(request)
      if response.code != "200" then
        # An error has occurred, log to roll bar and notify them
        raise RefreshTokenError.new("Failed to refresh FieldView token, response body: #{response.body}")
      else
        json = JSON.parse(response.body, symbolize_names: true)
        initialize(json)
      end
    end

    def execute_request!(method, path, headers: {}, params: {})
      next_token_header = headers[FieldView::NEXT_TOKEN_HEADER_KEY]
      # Upon initial request the api no longer wants us to send anything
      if next_token_header.to_s == "" then
        headers.delete(FieldView::NEXT_TOKEN_HEADER_KEY)
      end
      self.last_request = path
      if access_token_expired? && refresh_token_expired? then
        raise AllTokensExpiredError.new("All of your tokens have expired. " \
          "You'll need to re-log into FieldView.")
      end

      if access_token_expired? then
        refresh_access_token!()
      end
      uri = URI.parse("#{FieldView.api_base}#{FieldView.api_version}/#{path}")

      # TODO: Handle parameters
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = FieldView.api_base.start_with?("https")
      request = Net::HTTP.class_eval(method.to_s.capitalize).new(uri.request_uri)
      if method == :get then
        new_query_ar = URI.decode_www_form(uri.query || '') 
        params.each do |key,value|
          new_query_ar << [key.to_s, value.to_s]
        end
        uri.query = URI.encode_www_form(new_query_ar)
        request = Net::HTTP.class_eval(method.to_s.capitalize).new(uri.request_uri)
      else
        if params.is_a?(Hash)
          request.body = params.to_json()
        else
          request.body = params
        end
      end
      request["Accept"] = "*/*"
      request["Authorization"] = "Bearer #{self.access_token}"
      request["X-Api-Key"] = FieldView.x_api_key
      request["Content-Type"] = "application/json"
      headers.each do |header,value|
        request[header] = value.to_s
      end
      self.last_request_headers = request.to_hash

      response = nil
      begin
        response = http.request(request)
      rescue Zlib::DataError => e
        raise BadRequestError.new("A data error has occurred with Zlib while making the request, check the headers: #{request.to_hash}",
          http_body: params)
      end
      FieldView.handle_response_error_codes(response)
      return FieldViewResponse.new(response)
    end

    def self.build_token_request(url_params)
      uri = URI.parse(FieldView.oauth_token_base)
      new_query_ar = URI.decode_www_form(uri.query || '') 
      url_params.each do |param| 
        new_query_ar << param
      end
      uri.query = URI.encode_www_form(new_query_ar)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Post.new(uri.request_uri)
      request["Accept"] = "*/*"
      request["Authorization"] = "Basic #{Base64.encode64("#{FieldView.client_id}:#{FieldView.client_secret}").strip}"
      request["Content-Type"] = "application/x-www-form-urlencoded"
      return http, request
    end

    # Code will be collected from the redirect to your server
    def self.new_auth_token_with_code_from_redirect_code(code, redirect_uri: nil)
      http, request = build_token_request([
        ["grant_type", "authorization_code"],
        ["redirect_uri", redirect_uri || FieldView.redirect_uri],
        ["code", code]
      ])
      response = http.request(request)
      if response.code != "200" then
        raise AuthenticationError.new("Was unable to get a new auth token using the code provided. " \
          "See response body: #{response.body}")
      else
        json = JSON.parse(response.body, symbolize_names: true)
        return AuthToken.new(json)
      end
    end

    def to_s()
      [
        "AccessToken: #{self.access_token}, Expiration: #{self.access_token_expiration_at}",
        "RefreshToken: #{self.refresh_token}, Expiration: #{self.refresh_token_expiration_at}"
      ].join('\n')
    end
  end
end