module FieldView
  class Feature
    attr_accessor :type, :coordinates, :data

    def initialize(json_feature_object)
      # Use RGEO??
      self.type = json_feature_object[:type]
      self.coordinates = json_feature_object[:coordinates]
      self.data = json_feature_object
    end

    def point?()
      return !!(self.type =~ /\Apoint\z/i)
    end

    def multi_polygon?()
      return !!(self.type =~ /\Amultipolygon\z/i)
    end

    def polygon?()
      return !!(self.type =~ /\Apolygon\z/i)
    end
  end
end