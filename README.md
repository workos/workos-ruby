# workos-rb

WorkOS official Ruby gem for interacting with WorkOS APIs

## Installation

You don't need this source code unless you want to modify the gem. If you just
want to use the package, just run:

```sh
gem install workos
```

If you want to build the gem from source:

```sh
gem build workos.gemspec
```

### Requirements

- Ruby 2.3+.

# Release Notes

### December 27, 2019

- Removed the `redirect_uri` parameter from the `WorkOS::SSO.profile` function. Migrating existing code just requires removing the existing parameter:

  ```ruby
  # < December 27, 2019

  WorkOS::SSO.profile(
      code: 'acme.com',
      project_id: 'project_01DG5TGK363GRVXP3ZS40WNGEZ',
      redirect_uri: 'https://workos.com/callback'
  )
  ```

  ```ruby
  # > December 27, 2019

  WorkOS::SSO.profile(
      code: 'acme.com',
      project_id: 'project_01DG5TGK363GRVXP3ZS40WNGEZ'
  )
  ```
