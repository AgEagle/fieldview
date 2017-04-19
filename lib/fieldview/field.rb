module FieldView
  class Field < Requestable
    attr_accessor :id
    attr_accessor :name
    attr_accessor :boundary_id
    def initialize(json_object, auth_token = nil)
      self.id = json_object[:id]
      self.name = json_object[:name]
      self.boundary_id = json_object[:boundaryId]
      super(auth_token)
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