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

WorkOS.configure do |config|
  config.key = '[your api key]'
  config.timeout = 120
end
```

## SDK Versioning

For our SDKs WorkOS follows a Semantic Versioning ([SemVer](https://semver.org/)) process where all releases will have a version X.Y.Z (like 1.0.0) pattern wherein Z would be a bug fix (e.g., 1.0.1), Y would be a minor release (1.1.0) and X would be a major release (2.0.0). We permit any breaking changes to only be released in major versions and strongly recommend reading changelogs before making any major version upgrades.

## Beta Releases

WorkOS has features in Beta that can be accessed via Beta releases. We would love for you to try these
and share feedback with us before these features reach general availability (GA). To install a Beta version,
please follow the [installation steps](#installation) above using the Beta release version.

> Note: there can be breaking changes between Beta versions. Therefore, we recommend pinning the package version to a
> specific version. This way you can install the same version each time without breaking changes unless you are
> intentionally looking for the latest Beta version.

We highly recommend keeping an eye on when the Beta feature you are interested in goes from Beta to stable so that you
can move to using the stable version.

## More Information

* [Single Sign-On Guide](https://workos.com/docs/sso/guide)
* [Directory Sync Guide](https://workos.com/docs/directory-sync/guide)
* [Admin Portal Guide](https://workos.com/docs/admin-portal/guide)
* [Magic Link Guide](https://workos.com/docs/magic-link/guide)
