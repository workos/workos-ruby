# frozen_string_literal: true
# typed: false

require 'securerandom'

describe WorkOS::SSO do
  describe '.authorization_url' do
    context 'with a domain' do
      let(:args) do
        {
          domain: 'foo.com',
          client_id: 'workos-proj-123',
          redirect_uri: 'foo.com/auth/callback',
          state: {
            next_page: '/dashboard/edit',
          }.to_s,
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
          'client_id=workos-proj-123&redirect_uri=foo.com%2Fauth%2Fcallback' \
          '&response_type=code&state=%7B%3Anext_page%3D%3E%22%2Fdashboard%2F' \
          'edit%22%7D&domain=foo.com',
        )
      end
    end

    context 'with a provider' do
      let(:args) do
        {
          provider: 'GoogleOAuth',
          client_id: 'workos-proj-123',
          redirect_uri: 'foo.com/auth/callback',
          state: {
            next_page: '/dashboard/edit',
          }.to_s,
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
          'client_id=workos-proj-123&redirect_uri=foo.com%2Fauth%2Fcallback' \
          '&response_type=code&state=%7B%3Anext_page%3D%3E%22%2Fdashboard%2F' \
          'edit%22%7D&provider=GoogleOAuth',
        )
      end
    end

    context 'with neither domain or provider' do
      let(:args) do
        {
          client_id: 'workos-proj-123',
          redirect_uri: 'foo.com/auth/callback',
          state: {
            next_page: '/dashboard/edit',
          }.to_s,
        }
      end
      it 'raises an error' do
        expect do
          described_class.authorization_url(**args)
        end.to raise_error(
          ArgumentError,
          'Either domain or provider is required.',
        )
      end
    end

    context 'with an invalid provider' do
      let(:args) do
        {
          provider: 'Okta',
          client_id: 'workos-proj-123',
          redirect_uri: 'foo.com/auth/callback',
          state: {
            next_page: '/dashboard/edit',
          }.to_s,
        }
      end
      it 'raises an error' do
        expect do
          described_class.authorization_url(**args)
        end.to raise_error(
          ArgumentError,
          'Okta is not a valid value. `provider` must be in ["GoogleOAuth"]',
        )
      end
    end
  end

  describe '.profile' do
    before do
      WorkOS.key = 'api-key'
    end

    let(:args) do
      {
        code: SecureRandom.hex(10),
        client_id: 'workos-proj-123',
      }
    end

    let(:request_body) do
      {
        client_id: args[:client_id],
        client_secret: WorkOS.key,
        code: args[:code],
        grant_type: 'authorization_code',
      }
    end
    let(:user_agent) { 'user-agent-string' }
    let(:headers) { { 'User-Agent' => user_agent } }

    before do
      allow(described_class).to receive(:user_agent).and_return(user_agent)
    end

    context 'with a successful response' do
      let(:response_body) { File.read("#{SPEC_ROOT}/support/profile.txt") }

      before do
        stub_request(:post, 'https://api.workos.com/sso/token').
          with(headers: headers, body: request_body).
          to_return(status: 200, body: response_body)
      end

      it 'includes the SDK Version header' do
        described_class.profile(**args)

        expect(a_request(:post, 'https://api.workos.com/sso/token').
          with(headers: headers, body: request_body)).to have_been_made
      end

      it 'returns a WorkOS::Profile' do
        profile = described_class.profile(**args)
        expect(profile).to be_a(WorkOS::Profile)

        expectation = {
          connection_id: 'conn_01EMH8WAK20T42N2NBMNBCYHAG',
          connection_type: 'OktaSAML',
          email: 'demo@workos-okta.com',
          first_name: 'WorkOS',
          id: 'prof_01DRA1XNSJDZ19A31F183ECQW5',
          idp_id: '00u1klkowm8EGah2H357',
          last_name: 'Demo',
          raw_attributes: {
            email: 'demo@workos-okta.com',
            first_name: 'WorkOS',
            id: 'prof_01DRA1XNSJDZ19A31F183ECQW5',
            idp_id: '00u1klkowm8EGah2H357',
            last_name: 'Demo',
          },
        }

        expect(profile.to_json).to eq(expectation)
      end
    end

    context 'with an unprocessable request' do
      before do
        stub_request(:post, 'https://api.workos.com/sso/token').
          with(headers: headers, body: request_body).
          to_return(
            headers: { 'X-Request-ID' => 'request-id' },
            status: 422,
            body: { "message": 'some error message' }.to_json,
          )
      end

      it 'raises an exception with request ID' do
        expect do
          described_class.profile(**args)
        end.to raise_error(
          WorkOS::APIError,
          'some error message - request ID: request-id',
        )
      end
    end

    context 'with an expired code' do
      before do
        stub_request(:post, 'https://api.workos.com/sso/token').
          with(body: request_body).
          to_return(
            status: 201,
            headers: { 'X-Request-ID' => 'request-id' },
            body: {
              message: "The code '01DVX3C5Z367SFHR8QNDMK7V24'" \
                ' has expired or is invalid.',
            }.to_json,
          )
      end

      it 'raises an exception' do
        expect do
          described_class.profile(**args)
        end.to raise_error(
          WorkOS::APIError,
          "The code '01DVX3C5Z367SFHR8QNDMK7V24'" \
          ' has expired or is invalid. - request ID: request-id',
        )
      end
    end
  end

  describe '.create_connection' do
    before(:all) do
      WorkOS.key = 'key'
    end

    after(:all) do
      WorkOS.key = nil
    end

    context 'with a valid source' do
      it 'creates a connection' do
        VCR.use_cassette('sso/create_connection_with_valid_source') do
          connection = WorkOS::SSO.create_connection(
            source: 'draft_conn_01E6PK87QP6NQ29RRX0G100YGV',
          )

          expect(connection.id).to eq('conn_01E4F9T2YWZFD218DN04KVFDSY')
          expect(connection.connection_type).to eq('GoogleOAuth')
          expect(connection.name).to eq('Foo Corp')
          expect(connection.domains.first[:domain]).to eq('example.com')
        end
      end
    end

    context 'with an invalid source' do
      it 'raises an error' do
        VCR.use_cassette('sso/create_connection_with_invalid_source') do
          expect do
            WorkOS::SSO.create_connection(source: 'invalid')
          end.to raise_error(
            WorkOS::APIError,
            'Status 404, Not Found - request ID: ',
          )
        end
      end
    end
  end

  describe '.promote_draft_connection' do
    before(:all) do
      WorkOS.key = 'key'
    end

    after(:all) do
      WorkOS.key = nil
    end

    let(:token) { 'draft_conn_id' }
    let(:client_id) { 'proj_0239u590h' }

    context 'with a valid request' do
      before do
        stub_request(
          :post,
          "https://api.workos.com/draft_connections/#{token}/activate",
        ).to_return(status: 200)
      end
      it 'returns true' do
        response = described_class.promote_draft_connection(
          token: token,
        )

        expect(response).to be(true)
      end
    end

    context 'with an invalid request' do
      before do
        stub_request(
          :post,
          "https://api.workos.com/draft_connections/#{token}/activate",
        ).to_return(status: 403)
      end
      it 'returns true' do
        response = described_class.promote_draft_connection(
          token: token,
        )

        expect(response).to be(false)
      end
    end
  end
end
