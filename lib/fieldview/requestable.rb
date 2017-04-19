module FieldView
  class Requestable
    attr_accessor :auth_token

    def initialize(auth_token = nil)
      self.auth_token = auth_token
    end
  end
end