module FieldView
  class ListObject < Requestable
    attr_accessor :limit
    attr_reader :data, :last_http_status, :next_token, :listable
    include Enumerable

    def initialize(listable, auth_token, data, http_status, next_token: nil, limit: 100)
      @listable = listable
      @data = data
      @last_http_status = http_status
      @next_token = next_token
      @limit = limit
      super(auth_token)
    end

    def each(&blk)
      self.data.each(&blk)
    end

    def next_page!()
      return if !self.more_pages?()
      new_list = @listable.list(auth_token, limit: self.limit, next_token: self.next_token)
      initialize(new_list.listable, new_list.auth_token, 
        new_list.data, new_list.last_http_status, next_token: new_list.next_token, limit: new_list.limit)
    end

    # alias for more_pages
    def has_more?()
      return self.more_pages?()
    end

    def more_pages?()
      return Util.http_status_is_more_in_list?(self.last_http_status)
    end

    def restart!()
      @last_http_status = nil
      @next_token = nil
      next_page!()
    end
  end
end