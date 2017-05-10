module FieldView
  class Field < Requestable
    PATH = "fields"
    attr_accessor :id
    attr_accessor :name
    attr_accessor :boundary_id
    def initialize(json_object, auth_token = nil)
      self.id = json_object[:id]
      self.name = json_object[:name]
      self.boundary_id = json_object[:boundaryId]
      super(auth_token)
    end

    def self.retrieve(auth_token, id)
      response = auth_token.execute_request!(:get, "#{PATH}/#{id}")

      Util.verify_response_with_code("Field retrieve", response, 200)

      return new(response.data, auth_token)
    end

    def self.list(auth_token, limit: nil, next_token: nil)
      limit ||= FieldView.default_page_limit
      response = auth_token.execute_request!(:get, PATH,
        headers: {
          FieldView::NEXT_TOKEN_HEADER_KEY => next_token,
          FieldView::PAGE_LIMIT_HEADER_KEY => limit
          })

      Util.verify_response_with_code("Field list", response, 200, 206, 304)

      next_token = response.http_headers[FieldView::NEXT_TOKEN_HEADER_KEY]

      case response.http_status
      when 200, 206
        # 206: Partial result, will have more data
        # 200: When all the results were in the list
        return_data = response.data[:results]
      when 304
        # 304: Nothing modified since last request
        return_data = []
      end

      return ListObject.new(
        self,
        auth_token,
        return_data.collect { |i| Field.new(i, auth_token) },
        response.http_status,
        next_token: next_token,
        limit: limit)
    end

    def boundary
      @boundary ||= nil
      if @boundary.nil?
        @boundary = Boundary.new(self.auth_token.execute_request!(:get, "boundaries/#{self.boundary_id}").data)
      end
      return @boundary
    end
  end
end