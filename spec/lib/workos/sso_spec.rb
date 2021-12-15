# frozen_string_literal: true
# typed: false

require 'securerandom'

describe WorkOS::SSO do
  it_behaves_like 'client'

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

    context 'with a connection' do
      let(:args) do
        {
          connection: 'connection_123',
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
          'edit%22%7D&connection=connection_123',
        )
      end
    end

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

    context 'with a domain_hint' do
      let(:args) do
        {
          connection: 'connection_123',
          domain_hint: 'foo.com',
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
          '&response_type=code&state=%7B%3Anext_page%3D%3E%22%2Fdashboard%2' \
          'Fedit%22%7D&domain_hint=foo.com&connection=connection_123',
        )
      end
    end

    context 'with a login_hint' do
      let(:args) do
        {
          connection: 'connection_123',
          login_hint: 'foo@workos.com',
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
          '&response_type=code&state=%7B%3Anext_page%3D%3E%22%2Fdashboard%2' \
          'Fedit%22%7D&login_hint=foo%40workos.com&connection=connection_123',
        )
      end
    end

    context 'with an organization' do
      let(:args) do
        {
          organization: 'org_123',
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
          'edit%22%7D&organization=org_123',
        )
      end
    end

    context 'with neither connection, domain, provider, or organization' do
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
          'Either connection, domain, provider, or organization is required.',
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
          'Okta is not a valid value. `provider` must be in ["GoogleOAuth", "MicrosoftOAuth"]',
        )
      end
    end
  end

  describe '.get_profile' do
    it 'returns a profile' do
      VCR.use_cassette 'sso/profile' do
        profile = described_class.get_profile(access_token: 'access_token')

        expectation = {
          connection_id: 'conn_01E83FVYZHY7DM4S9503JHV0R5',
          connection_type: 'GoogleOAuth',
          email: 'bob.loblaw@workos.com',
          first_name: 'Bob',
          id: 'prof_01EEJTY9SZ1R350RB7B73SNBKF',
          idp_id: '116485463307139932699',
          last_name: 'Loblaw',
          organization_id: 'org_01FG53X8636WSNW2WEKB2C31ZB',
          raw_attributes: {
            email: 'bob.loblaw@workos.com',
            family_name: 'Loblaw',
            given_name: 'Bob',
            hd: 'workos.com',
            id: '116485463307139932699',
            locale: 'en',
            name: 'Bob Loblaw',
            picture: 'https://lh3.googleusercontent.com/a-/AOh14GyO2hLlgZvteDQ3Ldi3_-RteZLya0hWH7247Cam=s96-c',
            verified_email: true,
          },
        }

        expect(profile.to_json).to eq(expectation)
      end
    end
  end

  describe '.profile_and_token' do
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
        described_class.profile_and_token(**args)

        expect(a_request(:post, 'https://api.workos.com/sso/token').
          with(headers: headers, body: request_body)).to have_been_made
      end

      it 'returns a WorkOS::ProfileAndToken' do
        profile_and_token = described_class.profile_and_token(**args)
        expect(profile_and_token).to be_a(WorkOS::ProfileAndToken)

        expectation = {
          connection_id: 'conn_01EMH8WAK20T42N2NBMNBCYHAG',
          connection_type: 'OktaSAML',
          email: 'demo@workos-okta.com',
          first_name: 'WorkOS',
          id: 'prof_01DRA1XNSJDZ19A31F183ECQW5',
          idp_id: '00u1klkowm8EGah2H357',
          last_name: 'Demo',
          organization_id: 'org_01FG53X8636WSNW2WEKB2C31ZB',
          raw_attributes: {
            email: 'demo@workos-okta.com',
            first_name: 'WorkOS',
            id: 'prof_01DRA1XNSJDZ19A31F183ECQW5',
            idp_id: '00u1klkowm8EGah2H357',
            last_name: 'Demo',
          },
        }

        expect(profile_and_token.access_token).to eq('01DVX6QBS3EG6FHY2ESAA5Q65X')
        expect(profile_and_token.profile.to_json).to eq(expectation)
      end
    end

    context 'with an unprocessable request' do
      before do
        stub_request(:post, 'https://api.workos.com/sso/token').
          with(headers: headers, body: request_body).
          to_return(
            headers: { 'X-Request-ID' => 'request-id' },
            status: 422,
            body: { "error": 'some error', "error_description": 'some error description' }.to_json,
          )
      end

      it 'raises an exception with request ID' do
        expect do
          described_class.profile_and_token(**args)
        end.to raise_error(
          WorkOS::APIError,
          'error: some error, error_description: some error description - request ID: request-id',
        )
      end
    end

    context 'with an expired code' do
      before do
        stub_request(:post, 'https://api.workos.com/sso/token').
          with(body: request_body).
          to_return(
            status: 400,
            headers: { 'X-Request-ID' => 'request-id' },
            body: {
              "error": 'invalid_grant',
              "error_description": "The code '01DVX3C5Z367SFHR8QNDMK7V24' has expired or is invalid.",
            }.to_json,
          )
      end

      it 'raises an exception' do
        expect do
          described_class.profile_and_token(**args)
        end.to raise_error(
          WorkOS::APIError,
          "error: invalid_grant, error_description: The code '01DVX3C5Z367SFHR8QNDMK7V24'" \
          ' has expired or is invalid. - request ID: request-id',
        )
      end
    end
  end

  describe '.list_connections' do
    context 'with no options' do
      it 'returns connections and metadata' do
        expected_metadata = {
          'after' => nil,
          'before' => 'before_id',
        }

        VCR.use_cassette 'sso/list_connections/with_no_options' do
          connections = described_class.list_connections

          expect(connections.data.size).to eq(6)
          expect(connections.list_metadata).to eq(expected_metadata)
        end
      end
    end

    context 'with connection_type option' do
      it 'forms the proper request to the API' do
        request_args = [
          '/connections?connection_type=OktaSAML',
          'Content-Type' => 'application/json'
        ]

        expected_request = Net::HTTP::Get.new(*request_args)

        expect(Net::HTTP::Get).to receive(:new).with(*request_args).
          and_return(expected_request)

        VCR.use_cassette 'sso/list_connections/with_connection_type' do
          connections = described_class.list_connections(
            connection_type: 'OktaSAML',
          )

          expect(connections.data.size).to eq(10)
          expect(connections.data.first.connection_type).to eq('OktaSAML')
        end
      end
    end

    context 'with domain option' do
      it 'forms the proper request to the API' do
        request_args = [
          '/connections?domain=foo-corp.com',
          'Content-Type' => 'application/json'
        ]

        expected_request = Net::HTTP::Get.new(*request_args)

        expect(Net::HTTP::Get).to receive(:new).with(*request_args).
          and_return(expected_request)

        VCR.use_cassette 'sso/list_connections/with_domain' do
          connections = described_class.list_connections(
            domain: 'foo-corp.com',
          )

          expect(connections.data.size).to eq(1)
        end
      end
    end

    context 'with organization_id option' do
      it 'forms the proper request to the API' do
        request_args = [
          '/connections?organization_id=org_01F9293WD2PDEEV4Y625XPZVG7',
          'Content-Type' => 'application/json'
        ]

        expected_request = Net::HTTP::Get.new(*request_args)

        expect(Net::HTTP::Get).to receive(:new).with(*request_args).
          and_return(expected_request)

        VCR.use_cassette 'sso/list_connections/with_organization_id' do
          connections = described_class.list_connections(
            organization_id: 'org_01F9293WD2PDEEV4Y625XPZVG7',
          )

          expect(connections.data.size).to eq(1)
          expect(connections.data.first.organization_id).to eq(
            'org_01F9293WD2PDEEV4Y625XPZVG7',
          )
        end
      end
    end

    context 'with limit option' do
      it 'forms the proper request to the API' do
        request_args = [
          '/connections?limit=2',
          'Content-Type' => 'application/json'
        ]

        expected_request = Net::HTTP::Get.new(*request_args)

        expect(Net::HTTP::Get).to receive(:new).with(*request_args).
          and_return(expected_request)

        VCR.use_cassette 'sso/list_connections/with_limit' do
          connections = described_class.list_connections(
            limit: 2,
          )

          expect(connections.data.size).to eq(2)
        end
      end
    end

    context 'with before option' do
      it 'forms the proper request to the API' do
        request_args = [
          '/connections?before=conn_01FA3WGCWPCCY1V2FGES2FDNP7',
          'Content-Type' => 'application/json'
        ]

        expected_request = Net::HTTP::Get.new(*request_args)

        expect(Net::HTTP::Get).to receive(:new).with(*request_args).
          and_return(expected_request)

        VCR.use_cassette 'sso/list_connections/with_before' do
          connections = described_class.list_connections(
            before: 'conn_01FA3WGCWPCCY1V2FGES2FDNP7',
          )

          expect(connections.data.size).to eq(3)
        end
      end
    end

    context 'with after option' do
      it 'forms the proper request to the API' do
        request_args = [
          '/connections?after=conn_01FA3WGCWPCCY1V2FGES2FDNP7',
          'Content-Type' => 'application/json'
        ]

        expected_request = Net::HTTP::Get.new(*request_args)

        expect(Net::HTTP::Get).to receive(:new).with(*request_args).
          and_return(expected_request)

        VCR.use_cassette 'sso/list_connections/with_after' do
          connections = described_class.list_connections(
            after: 'conn_01FA3WGCWPCCY1V2FGES2FDNP7',
          )

          expect(connections.data.size).to eq(2)
        end
      end
    end
  end

  describe '.get_connection' do
    context 'with a valid id' do
      it 'gets the connection details' do
        VCR.use_cassette('sso/get_connection_with_valid_id') do
          connection = WorkOS::SSO.get_connection(
            id: 'conn_01FA3WGCWPCCY1V2FGES2FDNP7',
          )

          expect(connection.id).to eq('conn_01FA3WGCWPCCY1V2FGES2FDNP7')
          expect(connection.connection_type).to eq('OktaSAML')
          expect(connection.name).to eq('Foo Corp')
          expect(connection.domains.first[:domain]).to eq('foo-corp.com')
        end
      end
    end

    context 'with an invalid id' do
      it 'raises an error' do
        VCR.use_cassette('sso/get_connection_with_invalid_id') do
          expect do
            WorkOS::SSO.get_connection(id: 'invalid')
          end.to raise_error(
            WorkOS::APIError,
            'Status 404, Not Found - request ID: ',
          )
        end
      end
    end
  end

  describe '.delete_connection' do
    context 'with a valid id' do
      it 'returns true' do
        VCR.use_cassette('sso/delete_connection_with_valid_id') do
          response = WorkOS::SSO.delete_connection(
            id: 'conn_01EX55FRVN1V2PCA9YWTMZQMMQ',
          )

          expect(response).to be(true)
        end
      end
    end

    context 'with an invalid id' do
      it 'returns false' do
        VCR.use_cassette('sso/delete_connection_with_invalid_id') do
          expect do
            WorkOS::SSO.delete_connection(id: 'invalid')
          end.to raise_error(
            WorkOS::APIError,
            'Status 404, Not Found - request ID: ',
          )
        end
      end
    end
  end
end
