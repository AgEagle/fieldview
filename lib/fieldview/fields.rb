module FieldView
  class Fields
    PATH = "fields"
    def self.list(auth_token, limit: nil, next_token: nil)
      limit ||= FieldView.default_page_limit
      response = auth_token.execute_request(:get, PATH,
        headers: {
          FieldView::NEXT_TOKEN_HEADER_KEY => next_token,
          FieldView::PAGE_LIMIT_HEADER_KEY => limit
          })
      next_token = response.http_headers[FieldView::NEXT_TOKEN_HEADER_KEY]

      if (response.http_status == 200 || response.http_status == 206) then
        # 206: Partial result, will have more data
        # 200: When all the results were in the list
        return_data = response.data[:results]
      elsif (response.http_status == 304)
        # 304: Nothing modified since last request
        return_data = []
      else
        # This should never happen
        return_data = nil
      end
      
      return ListObject.new(
        self.class,
        auth_token,
        return_data.collect { |i| Field.new(i, auth_token) },
        response.http_status,
        next_token: next_token,
        limit: limit)
    end
  end
end