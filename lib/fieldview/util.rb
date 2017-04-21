module FieldView
  class Util
    def self.http_status_is_more_in_list?(http_status)
      return http_status.nil? || http_status.to_i == 206
    end

    def self.verify_response_with_code(message, fieldview_response, *acceptable_response_codes)
      if not acceptable_response_codes.include?(fieldview_response.http_status) then
        raise UnexpectedResponseError.new("#{message} expects #{acceptable_response_codes}",
          fieldview_response: fieldview_response)
      end
    end
  end
end