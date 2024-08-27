# frozen_string_literal: true

describe WorkOS::Session do

  let(:user_management) { instance_double('UserManagement') }
  let(:client_id) { 'test_client_id' }
  let(:cookie_password) { 'test_very_long_cookie_password__' }
  let(:session_data) { 'test_session_data' }
  let(:jwks_url) { 'https://api.workos.com/sso/jwks/client_123' }
  let(:jwks_hash) { '{"keys":[{"alg":"RS256","kty":"RSA","use":"sig","n":"test_n","e":"AQAB","kid":"sso_oidc_key_pair_123","x5c":["test"],"x5t#S256":"test"}]}' }
  let(:jwk) { JWT::JWK.new(OpenSSL::PKey::RSA.new(2048), { kid: 'sso_oidc_key_pair_123', use: 'sig', alg: 'RS256' }) }

  before do
    allow(user_management).to receive(:get_jwks_url).with(client_id).and_return(jwks_url)
    allow(Net::HTTP).to receive(:get).and_return(jwks_hash)
  end

  describe 'initialize' do
    it 'raises an error if cookie_password is nil or empty' do
      expect {
        WorkOS::Session.new(user_management: user_management, client_id: client_id, session_data: session_data, cookie_password: nil)
      }.to raise_error(ArgumentError, 'cookiePassword is required')

      expect {
        WorkOS::Session.new(user_management: user_management, client_id: client_id, session_data: session_data, cookie_password: '')
      }.to raise_error(ArgumentError, 'cookiePassword is required')
    end

    it 'initializes with valid parameters' do
      session = WorkOS::Session.new(user_management: user_management, client_id: client_id, session_data: session_data, cookie_password: cookie_password)
      expect(session.user_management).to eq(user_management)
      expect(session.client_id).to eq(client_id)
      expect(session.session_data).to eq(session_data)
      expect(session.cookie_password).to eq(cookie_password)
      expect(session.jwks.map(&:export)).to eq(JSON.parse(jwks_hash, symbolize_names: true)[:keys])
      expect(session.jwks_algorithms).to eq(['RS256'])
    end
  end

  describe '.authenticate' do
    let(:valid_access_token) do
      payload = { sid: 'session_id', org_id: 'org_id', role: 'role', permissions: ['read'], exp: Time.now.to_i + 3600 }
      headers = { kid: jwk[:kid] }
      JWT.encode(payload, jwk.signing_key, jwk[:alg], headers)
    end
    let(:session_data) { WorkOS::Session.seal_data({ access_token: valid_access_token, user: 'user', impersonator: 'impersonator' }, cookie_password) }

    it 'returns NO_SESSION_COOKIE_PROVIDED if session_data is nil' do
      session = WorkOS::Session.new(user_management: user_management, client_id: client_id, session_data: nil, cookie_password: cookie_password)
      result = session.authenticate
      expect(result).to eq({ authenticated: false, reason: 'NO_SESSION_COOKIE_PROVIDED' })
    end

    it 'returns INVALID_SESSION_COOKIE if session_data is invalid' do
      session = WorkOS::Session.new(user_management: user_management, client_id: client_id, session_data: 'invalid_data', cookie_password: cookie_password)
      result = session.authenticate
      expect(result).to eq({ authenticated: false, reason: 'INVALID_SESSION_COOKIE' })
    end

    it 'returns INVALID_JWT if access_token is invalid' do
      invalid_session_data = WorkOS::Session.seal_data({ access_token: 'invalid_token' }, cookie_password)
      session = WorkOS::Session.new(user_management: user_management, client_id: client_id, session_data: invalid_session_data, cookie_password: cookie_password)
      result = session.authenticate
      expect(result).to eq({ authenticated: false, reason: 'INVALID_JWT' })
    end

    it 'authenticates successfully with valid session_data' do
      session = WorkOS::Session.new(user_management: user_management, client_id: client_id, session_data: session_data, cookie_password: cookie_password)
      allow(session).to receive(:is_valid_jwt).and_return(true)
      allow(JWT).to receive(:decode).and_return([{ 'sid' => 'session_id', 'org_id' => 'org_id', 'role' => 'role', 'permissions' => ['read'] }])

      result = session.authenticate
      expect(result).to eq({
        authenticated: true,
        session_id: 'session_id',
        organization_id: 'org_id',
        role: 'role',
        permissions: ['read'],
        user: 'user',
        impersonator: 'impersonator',
        reason: nil
      })
    end
  end

  describe '.refresh' do
    let(:refresh_token) { 'test_refresh_token' }
    let(:session_data) { WorkOS::Session.seal_data({ refresh_token: refresh_token, user: 'user' }, cookie_password) }
    let(:auth_response) { double('AuthResponse', sealed_session: 'new_sealed_session') }

    before do
      allow(user_management).to receive(:authenticate_with_refresh_token).and_return(auth_response)
    end

    it 'returns INVALID_SESSION_COOKIE if session_data is invalid' do
      session = WorkOS::Session.new(user_management: user_management, client_id: client_id, session_data: 'invalid_data', cookie_password: cookie_password)
      result = session.refresh
      expect(result).to eq({ authenticated: false, reason: 'INVALID_SESSION_COOKIE' })
    end

    it 'refreshes the session successfully with valid session_data' do
      session = WorkOS::Session.new(user_management: user_management, client_id: client_id, session_data: session_data, cookie_password: cookie_password)
      result = session.refresh
      expect(result).to eq({
        authenticated: true,
        sealed_session: 'new_sealed_session',
        session: auth_response,
        reason: nil
      })
    end
  end

  describe '.get_logout_url' do
    let(:session) { WorkOS::Session.new(user_management: user_management, client_id: client_id, session_data: session_data, cookie_password: cookie_password) }

    context 'when authentication is successful' do
      before do
        allow(session).to receive(:authenticate).and_return({
          authenticated: true,
          session_id: 'session_id',
          reason: nil
        })
        allow(user_management).to receive(:get_logout_url).with(session_id: 'session_id').and_return('https://example.com/logout')
      end

      it 'returns the logout URL' do
        expect(session.get_logout_url).to eq('https://example.com/logout')
      end
    end

    context 'when authentication fails' do
      before do
        allow(session).to receive(:authenticate).and_return({
          authenticated: false,
          reason: 'Invalid session'
        })
      end

      it 'raises an error' do
        expect { session.get_logout_url }.to raise_error(RuntimeError, 'Failed to extract session ID for logout URL: Invalid session')
      end
    end
  end
end