module FieldView
  class Feature
    attr_accessor :type, :coordinates
    def initialize(json_feature_object)
      # Use RGEO??
      self.type = json_feature_object[:type]
      self.coordinates = json_feature_object[:coordinates]
    end

    def point?()
      return !!(self.type =~ /\Apoint\z/i)
    end

    def multi_polygon?()
      return !!(self.type =~ /\Amultipolygon\z/i)
    end
  end
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