# typed: false
# frozen_string_literal: true

require 'securerandom'

describe WorkOS::SSO do
  describe '.authorization_url' do
    let(:args) do
      {
        domain: 'foo.com',
        project_id: 'workos-proj-123',
        redirect_uri: 'foo.com/auth/callback',
        state: {
          next_page: '/dashboard/edit'
        }
      }
    end

    it 'returns a valid URL' do
      authorization_url = described_class.authorization_url(**args)

      expect(URI.parse(authorization_url)).to be_a URI
    end

    it 'returns the expected hostname' do
      authorization_url = described_class.authorization_url(**args)

      expect(URI.parse(authorization_url).host).to eq(WorkOS::API_HOSTNAME)
    end

    it 'returns the expected query string' do
      authorization_url = described_class.authorization_url(**args)

      expect(URI.parse(authorization_url).query).to eq(
        'domain=foo.com&client_id=workos-proj-123&redirect_uri=' \
        'foo.com%2Fauth%2Fcallback&response_type=code&' \
        'state=%7B%3Anext_page%3D%3E%22%2Fdashboard%2Fedit%22%7D',
      )
    end
  end

  describe '.profile' do
    before do
      WorkOS.key = 'api-key'
    end

    let(:args) do
      {
        code: SecureRandom.hex(10),
        project_id: 'workos-proj-123',
        redirect_uri: 'foo.com/auth/callback'
      }
    end

    let(:query) do
      {
        client_id: args[:project_id],
        client_secret: WorkOS.key,
        code: args[:code],
        grant_type: 'authorization_code',
        redirect_uri: args[:redirect_uri]
      }
    end

    context 'with a successful response' do
      let(:body) { File.read("#{SPEC_ROOT}/support/profile.txt") }

      before do
        stub_request(:post, 'https://api.workos.com/sso/token').
          with(query: query).
          to_return(status: 200, body: body)
      end

      it 'returns a WorkOS::Profile' do
        profile = described_class.profile(**args)

        expect(profile).to be_a(WorkOS::Profile)
      end
    end

    context 'with an expired code' do
      before do
        stub_request(:post, 'https://api.workos.com/sso/token').
          with(query: query).
          to_return(status: 200, body: '{ "message": "Code is expired"}')
      end

      xit 'raises an exception?' do
        profile = described_class.profile(**args)

        expect(profile).to be_a(WorkOS::Profile)
      end
    end

    context 'with an unprocessable request' do
      before do
        stub_request(:post, 'https://api.workos.com/sso/token').
          with(query: query).
          to_return(status: 422)
      end

      xit 'rasies an exception?' do
        profile = described_class.profile(**args)

        expect(profile).to be_a(WorkOS::Profile)
      end
    end
  end
end
