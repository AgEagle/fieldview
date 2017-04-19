# FieldView API Library

The FieldView Ruby library provides convenient access to the FieldView API from applications written in the Ruby language. It includes a pre-defined set of classes for API resources that are available currently from the API. You will need to get access from a Climate Corporation representative and the interface utilize OAUTH 2.0.

OAuth token refreshing is handled for your if for some reason the token expires in the middle of requests (this requires that you provide the `refresh_token` with the creation of the `AuthToken`).

## Listable Objects

FieldView returns pages of objects that are tracked via the headers, you cannot go back in pages easily (perhaps we could be tracking the next-token?). Use `more_pages?` on the listable object to see if there are more pages to be acquired by using `next_page!`. The `next_token` on listable objects can also be preserved when reaching the end of a list to see if there are any additional changes since the `next_token` was saved.

The raw data can be acquired by using `.data` on a listable object.

When finished you will want to store information of the `AuthToken` somewhere as it may have changed with requests.

## Usage

The library needs to be configured with your FieldView account's client secret,
client id, and x-api-key which would be provided to you by a Climate 
representative. Set these according to the their values

``` ruby
require "fieldview"

FieldView.client_id = "fake-client"
FieldView.client_secret = "fake-client-..."
FieldView.x_api_key = "..."

# Required if acquiring a new auth token without refresh tokens
FieldView.redirect_uri = "http://my.local.host/path/that/users/are/directed" 


# Get an Auth token
auth_token = FieldView::AuthToken.new_auth_token_with_code_from_redirect_code(<CODE>)

# Or initialize with previous information
auth_token = FieldView::AuthToken.new(
    access_token: <ATOKEN>, 
    expiration_at: <DATETIME>, # not required, but should be known
    refresh_token: <RTOKEN>,
    refresh_token_expiration_at: <DATETIME> # Not required, but should be known
)

# Or with just auth_token (assuming it hasn't expired)
auth_token = FieldView::AuthToken.new(access_token: <ATOKEN>)

# refresh token and a new access/refresh token will be associated with the object
auth_token = FieldView::AuthToken.new(refresh_token: <RTOKEN>) 

# Then you can do something like this:

fields = FieldView::Fields.list(auth_token)

fields.each do |field|
    puts field.boundary
end

fields.has_more?

```

## Uploading a File in Chunks

Assuming you've acquired an AuthToken, then you can do something like the following:

``` ruby
file = <PATH TO SOME FILE>
upload = FieldView::Upload.create(auth_token, 
    Digest::MD5.file(file).to_s, File.size(file), 
    <SOME FILE TYPE>)

start_bytes = 0
File.open(file, "rb") do|f|
    response = nil
    until f.eof?
        # since it's 0 based
        bytes = f.read(FieldView::Upload::REQUIRED_CHUNK_SIZE)
        end_bytes = start_bytes + bytes.bytesize - 1
        response = upload.upload_chunk(start_bytes, end_bytes, bytes)
        puts "Uploaded #{start_bytes}-#{end_bytes}/#{File.size(file)}"
        start_bytes = end_bytes + 1
    end
end
```

## Development

Run all tests:

    bundle exec rake

Run a single test suite:

    bundle exec ruby -Ilib/ test/field_view_test.rb

Run a single test:

    bundle exec ruby -Ilib/ test/field_view_test.rb -n /requires_redirect_uri/

## TODOs

- [ ] Thread safety of the auth token object since it's passed to all created objects
- [ ] Probably add configurable behavior for auto-refresh
- [ ] Change the configuration to non-static variables (at least the items that are required)
- [ ] Use faraday so that we are middleware agnostic

## Disclaimer

This Gem is in no way associated with The Climate Corporation, and they are in no way associated with it's support, maintenance, or updates.