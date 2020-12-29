# workos-ruby [![codecov](https://codecov.io/gh/workos-inc/workos-ruby/branch/master/graph/badge.svg)](https://codecov.io/gh/workos-inc/workos-ruby)

WorkOS official Ruby gem for interacting with WorkOS APIs

## Documentation

Complete documentation for the latest version of WorkOS Ruby Gem can be found [here](https://workos-inc.github.io/workos-ruby/).

## Installation

To get started, you can install the WorkOS gem via RubyGems with:

```ruby
gem install workos
```

If you're using Bundler to manage your application's gems, add the WorkOS gem to your Gemfile:

```ruby
source 'https://rubygems.org'

gem 'workos'
```

## Configuration

To use the SDK you must first provide your API key from the [WorkOS Developer Dashboard](https://dashboard.workos.com/api-keys).

You can do this through the `WORKOS_API_KEY` environment variable or by calling `WorkOS.key = [your API key]`.

The WorkOS Gem will read the environment variable `WORKOS_API_KEY`:

```sh
$ WORKOS_API_KEY=[your api key] ruby app.rb
```

Alternatively, you may set the key yourself, such as in an initializer in your application load path:

```ruby
# /config/initializers/workos.rb

WorkOS.key = '[your api key]'
```

## The SSO Module

The SSO Module provides convenient methods for authenticating a Single Sign On (SSO) user via WorkOS. WorkOS SSO follows the OAuth 2.0 specification.

First, you'll direct your SSO users to an `authorization_url`. They will sign in to their SSO account with their Identity Provider, and be redirected to a
callback URL that you set in your WorkOS Dashboard. The user will be redirected with a `code` URL parameter, which you can then exchange for a WorkOS::Profile
using the `WorkOS::SSO.get_profile` method.

See our Ruby SSO example app for a [complete example](https://github.com/workos-inc/ruby-sso-example).

```ruby
WorkOS::SSO.authorization_url(domain:, client_id:, redirect_uri:, state: {})
```

> Generate an authorization URL to intitiate the WorkOS OAuth2 workflow.

`WorkOS::SSO.authorization_url` accepts four arguments:

- `domain` (string) — the authenticating user's company domain, without protocol (ex. `example.com`)
- `client_id` (string) — your application's WorkOS [Client ID](https://dashboard.workos.com/sso/configuration) (ex. `project_01JG3BCPTRTSTTWQR4VSHXGWCQ`)
- `state` (optional, hash) — an optional hash used to manage state across authorization transactions (ex. `{ next_page: '/docs'}`)
- `redirect_uri` (string) — a callback URL where your application redirects the user-agent after an authorization code is granted (ex. `workos.dev/callback`). This must match one of your configured callback URLs for the associated environment on your WorkOS dashboard.

This method will return an OAuth2 query string of the form:

`https://${domain}/sso/authorize?response_type=code&client_id=${clientID}&redirect_uri=${redirectURI}&state=${state}`

For example, when used in a [Sinatra app](http://sinatrarb.com/):

```ruby
DOMAIN = 'example.com'
CLIENT_ID = '{clientId}'
REDIRECT_URI = 'http://localhost:4567/callback'

get '/auth' do
  authorization_url = WorkOS::SSO.authorization_url(
    domain: DOMAIN,
    client_id: CLIENT_ID,
    redirect_uri: REDIRECT_URI,
  )

  redirect authorization_url
end
```

The user would be redirected to:

`https://api.workos.com/sso/authorize?response_type=code&client_id={clientID}&redirect_uri=http://localhost:4567/callback`

WorkOS takes over from here, sending the user to authenticate with their IDP, and on successful login, returns
the user to your callback URL with a `code` parameter. You'll use `WorkOS::SSO.profile` to exchange the
code for a `WorkOS::Profile`.

```ruby
WorkOS::SSO.profile(code:, client_id:)
```

> Fetch a WorkOS::Profile for an authorized user.

`WorkOS::SSO.profile` accepts two arguments:

- `code` (string) — an opaque string provided by the authorization server; will be exchanged for an Access Token when the user's profile is sent
- `client_id` (string) — your application's WorkOS [Client ID](https://dashboard.workos.com/sso/configuration) (ex. `project_01JG3BCPTRTSTTWQR4VSHXGWCQ`)

This method will return an instance of a `WorkOS::Profile` with the following attributes:

```ruby
<WorkOS::Profile:0x00007fb6e4193d20
  @id="prof_01DRA1XNSJDZ19A31F183ECQW5",
  @email="demo@workos-okta.com",
  @first_name="WorkOS",
  @connection_id="conn_01EMH8WAK20T42N2NBMNBCYHAG",
  @connection_type="OktaSAML",
  @last_name="Demo",
  @idp_id="00u1klkowm8EGah2H357",
  @raw_attributes={
    :id=>"prof_01DRA1XNSJDZ19A31F183ECQW5",
    :email=>"demo@workos-okta.com",
    :first_name=>"WorkOS",
    :last_name=>"Demo",
    :idp_id=>"00u1klkowm8EGah2H357"
  },
>
```

Our Sinatra app can be extended to use this method:

```ruby
DOMAIN = 'example.com'
CLIENT_ID = '{clientId}'
REDIRECT_URI = 'http://localhost:4567/callback'

get '/auth' do
  authorization_url = WorkOS::SSO.authorization_url(
    domain: DOMAIN,
    client_id: CLIENT_ID,
    redirect_uri: REDIRECT_URI,
  )

  redirect authorization_url
end

get '/callback' do
  profile = WorkOS::SSO.profile(
    code: params['code'],
    client_id: CLIENT_ID,
  )

  session[:user] = profile.to_json

  redirect '/'
end
```

Given the `WorkOS::Profile`, you can now sign the user in according to your own authentication setup.

## The Magic Link Module

The Magic Link Module provides methods for authenticating a Passwordless user via WorkOS.

First, you'll create a Passwordless Session for a Magic Link connection.
Then, using the session ID, you'll email a user the Magic Link confirmation URL.
The user can then click on that link to be authenticated to your application.

> Create a Passwordless Session for a Magic Link Connection.

`WorkOS::Passwordless.create_session` accepts four arguments:

- `email` (string) - the email of the user to authenticate.
- `type` (string) - The type of Passwordless Session to create. Currently, the only supported value is `MagicLink`.
- `state` (optional, string) - Optional parameter that a Developer can choose to include in their authorization URL. If included, then the redirect URI received from WorkOS will contain the exact `state` that was passed in the authorization URL.
- `redirect_uri` (string) - a callback URL where your application redirects the user-agent after an authorization code is granted (ex. `workos.dev/callback`). This must match one of your configured callback URLs for the associated environment on your WorkOS dashboard.

This method will return a Passwordless Session object, containing the following attributes:

- `id` (string) - the unique ID of the session.
- `email` (string) - the email address of the user for the session.
- `expires_at` (date) - the ISO-8601 datetime at which the session expires.
- `link` (string) - the link for the user to authenticate with. You can use this link to send a custom email to the user, or send an email using the `WorkOS::Passwordless.send_session` method, described below.

> Email a user the Magic Link confirmation URL.

`WorkOS::Passwordless.send_session` accepts one argument:

- `id` (string) - the unique identifier of the Passwordless Session to send an email for.

This method will return a boolean confirming the Magic Link was sent.

> Example with Sinatra application

Our Sinatra app can be altered to use Magic Link:

```ruby
CLIENT_ID = '{clientId}'
REDIRECT_URI = 'http://localhost:4567/callback'

post '/passwordless-auth' do
  session = WorkOS::Passwordless.create_session(
    email: params[:email],
    type: 'MagicLink',
    redirect_uri: REDIRECT_URI
  )
  WorkOS::Passwordless.send_session(session.id)

  redirect '/check-email'
end

get '/callback' do
  profile = WorkOS::SSO.profile(
    code: params['code'],
    client_id: CLIENT_ID,
  )

  session[:user] = profile.to_json

  redirect '/'
end
```

## The Audit Trail Module

The Audit Trail Module provides methods for creating Audit Trail events on
WorkOS.

See our [Audit Trail
Overview](https://docs.workos.com/audit-trail/overview) for
more information.

```ruby
payload = {
  group: 'Foo Corp',
  location: '127.0.0.1',
  action: 'user.created',
  action_type: 'C',
  actor_name: 'Foo',
  actor_id: 'user_12345',
  target_name: 'Bar',
  target_id: 'user_67890',
  occurred_at: '2020-01-10T15:30:00-05:00',
  metadata: {
    source: 'Email',
  }
}

WorkOS::AuditTrail.create_event(event: payload)
```

### Idempotency

To perform an idempotent request, provide an additional idempotency_key
parameter to the `create_event` options.

```ruby
WorkOS::AuditTrail.create_event(event: payload, idempotency_key: 'key123456')
```

See our [API
Reference](https://docs.workos.com/audit-trail/api-reference#idempotency)
for more information on idempotency keys.
