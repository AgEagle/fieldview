module FieldView
  class Upload < Requestable
    CONTENT_TYPES = ["image/vnd.climate.thermal.geotiff", "image/vnd.climate.ndvi.geotiff",
      "image/vnd.climate.rgb.geotiff", "image/vnd.climate.raw.geotiff"]

    # 5 Megabytes is the current chunk size
    REQUIRED_CHUNK_SIZE = 5*1024*1024
    CHUNK_CONTENT_TYPE = "application/octet-stream"

    PATH = "uploads"
    attr_accessor :id, :content_length, :content_type

    def self.valid_content_type?(content_type)
      return CONTENT_TYPES.include?(content_type)
    end

    # Creates an upload with the specified items, all required.
    # will return an a new upload object that has it's ID which can be
    # used to upload. See the constant "CONTENT_TYPES" for the list 
    # of known types
    def self.create(auth_token, md5, content_length, content_type)
      if not self.valid_content_type?(content_type) then
        raise ArgumentError.new("content_type must be set to one of the following: #{CONTENT_TYPES.join(', ')}")
      end

      response = auth_token.execute_request!(:post, PATH,
        params: {
          "md5" => md5,
          "length" => content_length,
          "contentType" => content_type
      })

      Util.verify_response_with_code("Upload creation", response, 201)

      return new(response.http_body.gsub('"', ''), content_length, auth_token)
    end

    def initialize(id, content_length, auth_token = nil)
      self.id = id
      self.content_length = content_length.to_i
      if self.content_length <= 0 then
        raise ArgumentError.new("You must set content_length to a non-zero value")
      end
      super(auth_token)
    end

    # Upload a chunk of a file, specify the range of the bytes, 0 based, for the bytes
    # you're passing, for example, the first 256 bytes would be start_bytes = 0 and 
    # end_bytes = 255, with bytes = 256 byte size object
    def upload_chunk(start_bytes, end_bytes, bytes)
      if (end_bytes.to_i - start_bytes.to_i + 1) != bytes.bytesize ||
        bytes.bytesize > REQUIRED_CHUNK_SIZE then
        raise ArgumentError.new("End bytes (#{end_bytes}) - Start bytes (#{start_bytes})" \
          " must be equal to bytes (#{bytes}) and no greater than #{REQUIRED_CHUNK_SIZE}")
      end
      response = auth_token.execute_request!(:put, "#{PATH}/#{self.id}",
        headers: {
          "Content-Range" => "bytes #{start_bytes}-#{end_bytes}/#{self.content_length}",
          "Content-Length" => bytes.bytesize,
          "Content-Type" => CHUNK_CONTENT_TYPE,
          "Transfer-Encoding" => "chunked"
        },
        params: bytes)

      # We expect a 204
      Util.verify_response_with_code("Chunk upload", response, 204)

      return response
    end
  end
end