require File.expand_path('../test_helper', __FILE__)

class TestUpload < Minitest::Test

  def setup
    setup_for_api_requests
  end
  
  def teardown
    teardown_for_api_request
  end

  def test_expects_certain_status_code
    stub_request(:post, /uploads/).
      to_return(status: 200)

    assert_raises(FieldView::UnexpectedResponseError) do
      FieldView::Upload.create(new_auth_token, "dontcare", 5, "dontcare")
    end
  end
  
  def test_create()
    md5 = "eb782356d6011dab2b112bdcb098ec7d"
    uuid = "1a2623b3-d2a7-4e52-ba21-a3eb521a3208"
    content_length = 275
    content_type = "image/vnd.climate.thermal.geotiff"
    stub_request(:post, /uploads/).
      with(body: {
          "md5" => md5,
          "length" => content_length,
          "contentType" => content_type
      }).
      to_return(status: 201, body: %Q!"#{uuid}"!)

    auth_token = new_auth_token

    upload = FieldView::Upload.create(auth_token, md5, content_length, content_type)

    assert_equal uuid, upload.id
    assert_equal content_length, upload.content_length
    assert_equal auth_token, upload.auth_token
  end

  def test_checks_content_length
    assert_raises(ArgumentError) do
      # nil is going to result in 0 when converting to integer
      FieldView::Upload.new(1,nil,new_auth_token)
    end
  end

  def test_uploading_wrong_chunk_size
    upload = FieldView::Upload.new("dontcare", 
      50000000, new_auth_token)

    bytes = "12345678"
    start_bytes = 0
    end_bytes = 5
    assert_raises(ArgumentError, "Wrong byte start/end") do
      upload.upload_chunk(start_bytes, end_bytes, bytes)
    end

    bytes = "A" * (FieldView::Upload::REQUIRED_CHUNK_SIZE + 1)
    end_bytes = bytes.bytesize - 1
    assert_raises(ArgumentError, "Larger than the accepted chunk size") do
      upload.upload_chunk(start_bytes, end_bytes, bytes)
    end
  end

  def test_can_upload_chunk
    uuid = "1a2623b3-d2a7-4e52-ba21-a3eb521a3208"
    total_content_length = FieldView::Upload::REQUIRED_CHUNK_SIZE * 2
    upload = FieldView::Upload.new(uuid, 
      total_content_length, new_auth_token)

    chunk = "A"
    start_bytes = 0
    end_bytes = chunk.bytesize - 1

    stub_request(:put, /uploads\/#{uuid}/).
      with(headers: {
        content_range: "bytes #{start_bytes}-#{end_bytes}/#{total_content_length}",
        content_length: chunk.bytesize.to_s,
        content_type: "application/octet-stream",
        transfer_encoding: "chunked"
      }).
      to_return(status: 204, body: nil)
    assert upload.upload_chunk(start_bytes, end_bytes, chunk)
  end
end