module FieldView
  class ListObject
    attr_accessor :limit
    attr_reader :auth_token, :data, :last_http_status, :next_token, :listable
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

    def next_page!()
      return if !self.more_pages?()
      new_list = @listable.list(auth_token, limit: self.limit, next_token: self.next_token)
      @data = new_list.data
      @last_http_status = new_list.last_http_status
      @auth_token = new_list.auth_token
    end

    # alias for more_pages
    def has_more?()
      return self.more_pages?()
    end

    def more_pages?()
      return Util.http_status_is_more_in_list?(self.last_http_status)
    end
  end
end