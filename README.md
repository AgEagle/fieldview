# FieldView API Library

The FieldView Ruby library provides convenient access to the FieldView API from applications written in the Ruby language. It includes a pre-defined set of classes for API resources that are available currently from the API. You will need to get access from a Climate Corporation representative and the interface utilize OAUTH 2.0.

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

    bundle exec ruby -Ilib/ test/field_view_test.rb

Run a single test:

    bundle exec ruby -Ilib/ test/field_view_test.rb -n /client.id/

## Disclaimer

This Gem is in no way associated with The Climate Corporation, and they are in no way associated with it's support, maintenance, or updates.