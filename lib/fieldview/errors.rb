module FieldView
  # FieldViewError is the base error from which all other more specific FieldView
  # errors derive.
  class FieldViewError < StandardError
    attr_reader :message

    # These fields are now available as part of #response and that usage should
    # be preferred.
    attr_reader :http_body
    attr_reader :http_headers
    attr_reader :http_status
    attr_reader :request_id

    attr_accessor :response
    # Initializes a FieldViewError.
    def initialize(message=nil, http_status: nil, http_body: nil,
                   http_headers: nil, fieldview_response: nil)
      @message = message
      if fieldview_response then
        self.response = fieldview_response
        http_status = fieldview_response.http_status
        http_body = fieldview_response.http_body
        http_headers = fieldview_response.http_headers
      end
      @http_status = http_status
      @http_body = http_body
      @http_headers = http_headers || {}
      @request_id = @http_headers[FieldView::REQUEST_ID_HEADER_KEY]
    end

    def to_s
      status_string = @http_status.nil? ? "" : "(Status #{@http_status}) "
      id_string = @request_id.nil? ? "" : "(Request #{@request_id}) "
      "#{status_string}#{id_string}#{@message}"
    end
  end

  # AuthenticationError is raised when invalid credentials are used to connect
  # to FieldView's servers.
  class AuthenticationError < FieldViewError
  end

  # Raised when all the tokens expired and nothing can be done.
  class AllTokensExpiredError < FieldViewError
  end

  # Raised when access resources you don't have access to
  class PermissionError < FieldViewError
  end

  # Raised when a refresh token is attempted to be used but it can't be
  class RefreshTokenError < FieldViewError
  end

  # Raised when too many requests are being made
  class RateLimitError < FieldViewError
  end

  # Raised when accessing a non-existent resource
  class InvalidRequestError < FieldViewError
  end

  # Raised when something goes wrong with FieldView
  class InternalServerError < FieldViewError
  end

  # Raised when the server is busy
  class ServerBusyError < FieldViewError
  end

  # Raised when a response code that is non-breaking is outside
  # API specifications, ex: We expect a 201 when creating an upload, but it
  # returns a 200
  class UnexpectedResponseError < FieldViewError
  end
end