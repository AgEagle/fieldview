module FieldView
  class Util
    def self.http_status_is_more_in_list?(http_status)
      return http_status.to_i == 206
    end
  end
end