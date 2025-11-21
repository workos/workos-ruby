# frozen_string_literal: true

describe WorkOS::Session do
  let(:client_id) { 'test_client_id' }
  let(:cookie_password) { 'test_very_long_cookie_password__' }
  let(:session_data) { 'test_session_data' }
  let(:jwks_url) { 'https://api.workos.com/sso/jwks/client_123' }
  let(:jwks_hash) { '{"keys":[{"alg":"RS256","kty":"RSA","use":"sig","n":"test_n","e":"AQAB","kid":"sso_oidc_key_pair_123","x5c":["test"],"x5t#S256":"test"}]}' } # rubocop:disable all
  let(:jwk) { JWT::JWK.new(OpenSSL::PKey::RSA.new(2048), { kid: 'sso_oidc_key_pair_123', use: 'sig', alg: 'RS256' }) }

  before do
    allow(Net::HTTP).to receive(:get).and_return(jwks_hash)
  end

  describe 'initialize' do
    let(:user_management) { instance_double('UserManagement') }

    before do
      allow(user_management).to receive(:get_jwks_url).with(client_id).and_return(jwks_url)
    end

    describe 'JWKS caching' do
      before do
        WorkOS::Cache.clear
      end

      it 'caches and returns JWKS' do
        expect(Net::HTTP).to receive(:get).once
        session1 = WorkOS::Session.new(
          user_management: user_management,
          client_id: client_id,
          session_data: session_data,
          cookie_password: cookie_password,
        )

        session2 = WorkOS::Session.new(
          user_management: user_management,
          client_id: client_id,
          session_data: session_data,
          cookie_password: cookie_password,
        )

        expect(session1.jwks.map(&:export)).to eq(session2.jwks.map(&:export))
      end

      it 'fetches JWKS from remote when cache is expired' do
        expect(Net::HTTP).to receive(:get).twice
        session1 = WorkOS::Session.new(
          user_management: user_management,
          client_id: client_id,
          session_data: session_data,
          cookie_password: cookie_password,
        )

        allow(Time).to receive(:now).and_return(Time.now + 301)

        session2 = WorkOS::Session.new(
          user_management: user_management,
          client_id: client_id,
          session_data: session_data,
          cookie_password: cookie_password,
        )

        expect(session1.jwks.map(&:export)).to eq(session2.jwks.map(&:export))
      end
    end

    it 'raises an error if cookie_password is nil or empty' do
      expect do
        WorkOS::Session.new(
          user_management: user_management,
          client_id: client_id,
          session_data: session_data,
          cookie_password: nil,
        )
      end.to raise_error(ArgumentError, 'cookiePassword is required')

      expect do
        WorkOS::Session.new(
          user_management: user_management,
          client_id: client_id,
          session_data: session_data,
          cookie_password: '',
        )
      end.to raise_error(ArgumentError, 'cookiePassword is required')
    end

    it 'initializes with valid parameters' do
      session = WorkOS::Session.new(
        user_management: user_management,
        client_id: client_id,
        session_data: session_data,
        cookie_password: cookie_password,
      )
      expect(session.user_management).to eq(user_management)
      expect(session.client_id).to eq(client_id)
      expect(session.session_data).to eq(session_data)
      expect(session.cookie_password).to eq(cookie_password)
      expect(session.jwks.map(&:export)).to eq(JSON.parse(jwks_hash, symbolize_names: true)[:keys])
      expect(session.jwks_algorithms).to eq(['RS256'])
    end
  end

  describe '.authenticate' do
    let(:user_management) { instance_double('UserManagement') }
    let(:payload) do
      {
        sid: 'session_id',
        org_id: 'org_id',
        role: 'role',
        roles: ['role'],
        permissions: ['read'],
        exp: Time.now.to_i + 3600,
      }
    end
    let(:valid_access_token) { JWT.encode(payload, jwk.signing_key, jwk[:alg], { kid: jwk[:kid] }) }
    let(:session_data) do
      WorkOS::Session.seal_data({
                                  access_token: valid_access_token,
                                  user: 'user',
                                  impersonator: 'impersonator',
                                }, cookie_password,)
    end

    before do
      allow(user_management).to receive(:get_jwks_url).with(client_id).and_return(jwks_url)
    end

    it 'returns NO_SESSION_COOKIE_PROVIDED if session_data is nil' do
      session = WorkOS::Session.new(
        user_management: user_management,
        client_id: client_id,
        session_data: nil,
        cookie_password: cookie_password,
      )
      result = session.authenticate
      expect(result).to eq({ authenticated: false, reason: 'NO_SESSION_COOKIE_PROVIDED' })
    end

    it 'returns INVALID_SESSION_COOKIE if session_data is invalid' do
      session = WorkOS::Session.new(
        user_management: user_management,
        client_id: client_id,
        session_data: 'invalid_data',
        cookie_password: cookie_password,
      )
      result = session.authenticate
      expect(result).to eq({ authenticated: false, reason: 'INVALID_SESSION_COOKIE' })
    end

    it 'returns INVALID_JWT if access_token is invalid' do
      invalid_session_data = WorkOS::Session.seal_data({ access_token: 'invalid_token' }, cookie_password)
      session = WorkOS::Session.new(
        user_management: user_management,
        client_id: client_id,
        session_data: invalid_session_data,
        cookie_password: cookie_password,
      )
      result = session.authenticate
      expect(result).to eq({ authenticated: false, reason: 'INVALID_JWT' })
    end

    it 'returns INVALID_JWT without token data when session is expired' do
      session = WorkOS::Session.new(
        user_management: user_management,
        client_id: client_id,
        session_data: session_data,
        cookie_password: cookie_password,
      )
      allow_any_instance_of(JWT::Decode).to receive(:verify_signature).and_return(true)
      allow(Time).to receive(:now).and_return(Time.at(9_999_999_999))
      result = session.authenticate
      expect(result).to eq({ authenticated: false, reason: 'INVALID_JWT' })
    end

    it 'returns INVALID_JWT with full token data when session is expired and include_expired is true' do
      session = WorkOS::Session.new(
        user_management: user_management,
        client_id: client_id,
        session_data: session_data,
        cookie_password: cookie_password,
      )
      allow_any_instance_of(JWT::Decode).to receive(:verify_signature).and_return(true)
      allow(Time).to receive(:now).and_return(Time.at(9_999_999_999))
      result = session.authenticate(include_expired: true)
      expect(result).to eq({
                             authenticated: false,
                             session_id: 'session_id',
                             organization_id: 'org_id',
                             role: 'role',
                             roles: ['role'],
                             permissions: ['read'],
                             feature_flags: nil,
                             entitlements: nil,
                             user: 'user',
                             impersonator: 'impersonator',
                             reason: 'INVALID_JWT',
                           })
    end

    it 'authenticates successfully with valid session_data' do
      session = WorkOS::Session.new(
        user_management: user_management,
        client_id: client_id,
        session_data: session_data,
        cookie_password: cookie_password,
      )
      allow_any_instance_of(JWT::Decode).to receive(:verify_signature).and_return(true)
      result = session.authenticate
      expect(result).to eq({
                             authenticated: true,
                             session_id: 'session_id',
                             organization_id: 'org_id',
                             role: 'role',
                             roles: ['role'],
                             permissions: ['read'],
                             feature_flags: nil,
                             entitlements: nil,
                             user: 'user',
                             impersonator: 'impersonator',
                             reason: nil,
                           })
    end

    describe 'with entitlements' do
      let(:payload) do
        {
          sid: 'session_id',
          org_id: 'org_id',
          role: 'role',
          roles: ['role'],
          permissions: ['read'],
          entitlements: ['billing'],
          exp: Time.now.to_i + 3600,
        }
      end

      it 'includes entitlements in the result' do
        session = WorkOS::Session.new(
          user_management: user_management,
          client_id: client_id,
          session_data: session_data,
          cookie_password: cookie_password,
        )
        allow_any_instance_of(JWT::Decode).to receive(:verify_signature).and_return(true)
        result = session.authenticate
        expect(result).to eq({
                               authenticated: true,
                               session_id: 'session_id',
                               organization_id: 'org_id',
                               role: 'role',
                               roles: ['role'],
                               permissions: ['read'],
                               entitlements: ['billing'],
                               feature_flags: nil,
                               user: 'user',
                               impersonator: 'impersonator',
                               reason: nil,
                             })
      end
    end

    describe 'with feature flags' do
      let(:payload) do
        {
          sid: 'session_id',
          org_id: 'org_id',
          role: 'role',
          roles: ['role'],
          permissions: ['read'],
          feature_flags: ['new_feature_enabled'],
          exp: Time.now.to_i + 3600,
        }
      end

      it 'includes feature flags in the result' do
        session = WorkOS::Session.new(
          user_management: user_management,
          client_id: client_id,
          session_data: session_data,
          cookie_password: cookie_password,
        )
        allow_any_instance_of(JWT::Decode).to receive(:verify_signature).and_return(true)
        result = session.authenticate
        expect(result).to eq({
                               authenticated: true,
                               session_id: 'session_id',
                               organization_id: 'org_id',
                               role: 'role',
                               roles: ['role'],
                               permissions: ['read'],
                               entitlements: nil,
                               feature_flags: ['new_feature_enabled'],
                               user: 'user',
                               impersonator: 'impersonator',
                               reason: nil,
                             })
      end
    end
  end

  describe '.refresh' do
    let(:user_management) { instance_double('UserManagement') }
    let(:refresh_token) { 'test_refresh_token' }
    let(:session_data) { WorkOS::Session.seal_data({ refresh_token: refresh_token, user: 'user' }, cookie_password) }
    let(:auth_response) { double('AuthResponse', sealed_session: 'new_sealed_session') }

    before do
      allow(user_management).to receive(:get_jwks_url).with(client_id).and_return(jwks_url)
      allow(user_management).to receive(:authenticate_with_refresh_token).and_return(auth_response)
    end

    it 'returns INVALID_SESSION_COOKIE if session_data is invalid' do
      session = WorkOS::Session.new(
        user_management: user_management,
        client_id: client_id,
        session_data: 'invalid_data',
        cookie_password: cookie_password,
      )
      result = session.refresh
      expect(result).to eq({ authenticated: false, reason: 'INVALID_SESSION_COOKIE' })
    end

    it 'refreshes the session successfully with valid session_data' do
      session = WorkOS::Session.new(
        user_management: user_management,
        client_id: client_id,
        session_data: session_data,
        cookie_password: cookie_password,
      )
      result = session.refresh
      expect(result).to eq({
                             authenticated: true,
                             sealed_session: 'new_sealed_session',
                             session: auth_response,
                             reason: nil,
                           })
    end
  end

  describe '.get_logout_url' do
    let(:session) do
      WorkOS::Session.new(
        user_management: WorkOS::UserManagement,
        client_id: client_id,
        session_data: session_data,
        cookie_password: cookie_password,
      )
    end

    context 'when authentication is successful' do
      before do
        allow(session).to receive(:authenticate).and_return({
                                                              authenticated: true,
                                                              session_id: 'session_123abc',
                                                              reason: nil,
                                                            })
      end

      it 'returns the logout URL' do
        expect(session.get_logout_url).to eq('https://api.workos.com/user_management/sessions/logout?session_id=session_123abc')
      end

      context 'when given a return_to URL' do
        it 'returns the logout URL with the return_to parameter' do
          expect(session.get_logout_url(return_to: 'https://example.com/signed-out')).to eq(
            'https://api.workos.com/user_management/sessions/logout?session_id=session_123abc&return_to=https%3A%2F%2Fexample.com%2Fsigned-out',
          )
        end
      end
    end

    context 'when authentication fails' do
      before do
        allow(session).to receive(:authenticate).and_return({
                                                              authenticated: false,
                                                              reason: 'Invalid session',
                                                            })
      end

      it 'raises an error' do
        expect { session.get_logout_url }.to raise_error(
          RuntimeError, 'Failed to extract session ID for logout URL: Invalid session',
        )
      end
    end
  end
end
