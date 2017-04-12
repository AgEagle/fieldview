module FieldView
  class FieldViewResponse
    attr_accessor :request_id
    attr_accessor :http_body
    attr_accessor :http_headers
    attr_accessor :http_status
    attr_accessor :data
    def initialize(response)
      self.http_headers = {}
      response.each_capitalized_name do |n|
        self.http_headers[n] = response[n]
      end
      
      self.http_body = response.body
      begin
        self.data = JSON.parse(response.body, symbolize_names: true)
      rescue JSON::ParserError => e
        self.data = nil
      end
      self.http_status = response.code.to_i
      self.request_id = self.http_headers[FieldView::REQUEST_ID_HEADER_KEY]
    end
  end
end