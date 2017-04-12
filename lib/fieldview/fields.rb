module FieldView
  class Fields
    def self.list(auth_token, next_token=nil)
      response = auth_token.execute_request(:get, "fields",
        headers: {
          FieldView::NEXT_TOKEN_HEADER_KEY => next_token
          })
      
      next_token = response.http_headers[FieldView::NEXT_TOKEN_HEADER_KEY]
      last_response = response.http_status

      return_data = nil
      case response.http_status
      # Partial result, will have more data
      when 206
        return_data = response.data[:results]
      # Nothing modified since last request
      when 304
        return_data = []
      # When all the results were in the list
      when 200
        return_data = response.data[:results]
      end

      return return_data.collect { |i| Field.new(i, self.auth_token) }
    end
  end
end