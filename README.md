# WorkOS Ruby Library

The WorkOS library for Ruby provides convenient access to the WorkOS API from applications written in Ruby.

## Documentation

See the [API Reference](https://workos.com/docs/reference/client-libraries) for Ruby usage examples.

## Installation

Install the package with:

```
gem install workos
```

If you're using Bundler to manage your application's gems, add the WorkOS gem to your Gemfile:

```
source 'https://rubygems.org'

gem 'workos'
```

## Configuration

To use the library you must provide an API key, located in the WorkOS dashboard, as an environment variable `WORKOS_API_KEY`:

```sh
$ WORKOS_API_KEY=[your api key] ruby app.rb
```

Or, you may set the key yourself, such as in an initializer in your application load path:

```ruby
# /config/initializers/workos.rb

WorkOS.key = '[your api key]'
```

## More Information

* [Single Sign-On Guide](https://workos.com/docs/sso/guide)
* [Directory Sync Guide](https://workos.com/docs/directory-sync/guide)
* [Admin Portal Guide](https://workos.com/docs/admin-portal/guide)
* [Magic Link Guide](https://workos.com/docs/magic-link/guide)
