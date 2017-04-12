module FieldView
  class ListObject
    attr_accessor :limit
    attr_reader :auth_token, :data, :last_http_status, :next_token
    include Enumerable

    def initialize(listable, auth_token, data, http_status, next_token: nil, limit: 100)
      @listable = listable
      @auth_token = auth_token
      @data = data
      @last_http_status = http_status
      @next_token = next_token
      @limit = 100
    end

    def each(&blk)
      self.data.each(&blk)
    end
  end
end