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
    expiration_at: <DATETIME>,
    refresh_token: <RTOKEN>,
    refresh_token_expiration_at: <DATETIME>)

# Or with just auth_token (assuming it hasn't expired)
auth_token = FieldView::AuthToken.new(access_token: <ATOKEN>)

# refresh token and a new access/refresh token will be associated with the object
auth_token = FieldView::AuthToken.new(refresh_token: <RTOKEN>) 


```

## Development

Run all tests:

    bundle exec rake

Run a single test suite:

    bundle exec ruby -Ilib/ test/test_field_view.rb

Run a single test:

    bundle exec ruby -Ilib/ test/stripe/test_field_view.rb -n /client.id/

