# typed: false
# frozen_string_literal: true

describe WorkOS::SSO do
  before do
    WorkOS.key = 'workos_key'
  end

  describe '.get_authorization_url' do
    let(:args) do
      {
        domain: 'foo.com',
        project_id: 'workos-proj-123',
        redirect_uri: 'foo.com/auth/callback',
        state: {
          code: 'sso-callback-auth-code'
        }
      }
    end

    it 'returns a valid URL' do
      authorization_url = described_class.get_authorization_url(**args)

      expect(URI.parse(authorization_url)).to be_a URI
    end

    it 'returns the expected hostname' do
      authorization_url = described_class.get_authorization_url(**args)

      expect(URI.parse(authorization_url).host).to eq(WorkOS::API_HOSTNAME)
    end

    it 'returns the expected query string' do
      authorization_url = described_class.get_authorization_url(**args)

      expect(URI.parse(authorization_url).query).to eq(
        'domain=foo.com&client_id=workos-proj-123&redirect_uri=' \
        'foo.com%2Fauth%2Fcallback&response_type=code&' \
        'state=%7B%3Acode%3D%3E%22sso-callback-auth-code%22%7D',
      )
    end
  end
end
