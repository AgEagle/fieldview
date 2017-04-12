module FieldView
  class ListObject
    include Enumerable

    def initialize(auth_token, data, http_status, next_token: nil)
      super
    end

    def each(&blk)
      self.data.each(&blk)
    end
  end
end