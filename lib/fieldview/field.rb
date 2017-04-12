module FieldView
  class Field
    attr_accessor :id
    attr_accessor :name
    attr_accessor :boundary_id
    attr_accessor :auth_token
    def initialize(json_object, auth_token = nil)
      self.id = json_object[:id]
      self.name = json_object[:name]
      self.boundary_id = json_object[:boundaryId]
      self.auth_token = auth_token
    end

    def boundary
      @boundary ||= nil
      if @boundary.nil?
        @boundary = self.auth_token.execute_request(:get, "boundaries/#{self.boundary_id}")
      end
      return @boundary
    end
  end
end