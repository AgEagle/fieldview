module FieldView
  class Boundary
    attr_accessor :id, :units, :area, :centroid, :geometry
    def initialize(json_object)
      self.id = json_object[:id]
      self.area = json_object[:area][:q]
      self.units = json_object[:area][:u]
      self.centroid = Feature.new(json_object[:centroid])
      self.geometry = Feature.new(json_object[:geometry])
    end
  end
end