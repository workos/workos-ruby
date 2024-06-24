# frozen_string_literal: true

describe WorkOS::UserManagement do
  it_behaves_like 'client'

  describe '.authorization_url' do
    context 'with a provider' do
      let(:args) do
        {
          provider: 'authkit',
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

        expect(URI.parse(authorization_url).host).to eq(WorkOS.config.api_hostname)
      end

      it 'returns the expected query string' do
        authorization_url = described_class.authorization_url(**args)

        expect(URI.parse(authorization_url).query).to eq(
          'client_id=workos-proj-123&redirect_uri=foo.com%2Fauth%2Fcallback' \
          '&response_type=code&state=%7B%3Anext_page%3D%3E%22%2Fdashboard%2F' \
          'edit%22%7D&provider=authkit',
        )
      end
    end

    context 'with a connection selector' do
      let(:args) do
        {
          connection_id: 'connection_123',
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

        expect(URI.parse(authorization_url).host).to eq(WorkOS.config.api_hostname)
      end

      it 'returns the expected query string' do
        authorization_url = described_class.authorization_url(**args)

        expect(URI.parse(authorization_url).query).to eq(
          'client_id=workos-proj-123&redirect_uri=foo.com%2Fauth%2Fcallback' \
          '&response_type=code&state=%7B%3Anext_page%3D%3E%22%2Fdashboard%2F' \
          'edit%22%7D&connection_id=connection_123',
        )
      end
    end

    context 'with an organization selector' do
      let(:args) do
        {
          organization_id: 'org_123',
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

        expect(URI.parse(authorization_url).host).to eq(WorkOS.config.api_hostname)
      end

      it 'returns the expected query string' do
        authorization_url = described_class.authorization_url(**args)

        expect(URI.parse(authorization_url).query).to eq(
          'client_id=workos-proj-123&redirect_uri=foo.com%2Fauth%2Fcallback' \
          '&response_type=code&state=%7B%3Anext_page%3D%3E%22%2Fdashboard%2F' \
          'edit%22%7D&organization_id=org_123',
        )
      end
    end

    context 'with a domain hint' do
      let(:args) do
        {
          connection_id: 'connection_123',
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

        expect(URI.parse(authorization_url).host).to eq(WorkOS.config.api_hostname)
      end

      it 'returns the expected query string' do
        authorization_url = described_class.authorization_url(**args)

        expect(URI.parse(authorization_url).query).to eq(
          'client_id=workos-proj-123&redirect_uri=foo.com%2Fauth%2Fcallback' \
          '&response_type=code&state=%7B%3Anext_page%3D%3E%22%2Fdashboard%2' \
          'Fedit%22%7D&domain_hint=foo.com&connection_id=connection_123',
        )
      end
    end

    context 'with a login hint' do
      let(:args) do
        {
          connection_id: 'connection_123',
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

        expect(URI.parse(authorization_url).host).to eq(WorkOS.config.api_hostname)
      end

      it 'returns the expected query string' do
        authorization_url = described_class.authorization_url(**args)

        expect(URI.parse(authorization_url).query).to eq(
          'client_id=workos-proj-123&redirect_uri=foo.com%2Fauth%2Fcallback' \
          '&response_type=code&state=%7B%3Anext_page%3D%3E%22%2Fdashboard%2' \
          'Fedit%22%7D&login_hint=foo%40workos.com&connection_id=connection_123',
        )
      end
    end

    context 'with neither connection_id, organization_id or provider' do
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
          'Either connection ID, organization ID, or provider is required.',
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
          'Okta is not a valid value. `provider` must be in ' \
          '["GitHubOAuth", "GoogleOAuth", "MicrosoftOAuth", "authkit"]',
        )
      end
    end
  end

  describe '.get_user' do
    context 'with a valid id' do
      it 'returns a user' do
        VCR.use_cassette 'user_management/get_user' do
          user = described_class.get_user(
            id: 'user_01HP0B4ZV2FWWVY0BF16GFDAER',
          )

          expect(user.id.instance_of?(String))
          expect(user.instance_of?(WorkOS::User))
        end
      end
    end

    context 'with an invalid id' do
      it 'returns an error' do
        expect do
          described_class.get_user(
            id: 'invalid_user_id',
          ).to raise_error(WorkOS::APIError)
        end
      end
    end
  end

  describe '.list_users' do
    context 'with no options' do
      it 'returns a list of users' do
        expected_metadata = {
          'after' => nil,
          'before' => 'before-id',
        }

        VCR.use_cassette 'user_management/list_users/no_options' do
          users = described_class.list_users

          expect(users.data.size).to eq(2)
          expect(users.list_metadata).to eq(expected_metadata)
        end
      end
    end

    context 'with options' do
      it 'returns a list of matching users' do
        request_args = [
          '/user_management/users?email=lucy.lawless%40example.com&'\
          'order=desc&'\
          'limit=5',
          'Content-Type' => 'application/json'
        ]

        expected_request = Net::HTTP::Get.new(*request_args)

        expect(Net::HTTP::Get).to receive(:new).with(*request_args).
          and_return(expected_request)

        VCR.use_cassette 'user_management/list_users/with_options' do
          users = described_class.list_users(
            email: 'lucy.lawless@example.com',
            order: 'desc',
            limit: '5',
          )

          expect(users.data.size).to eq(1)
          expect(users.data[0].email).to eq('lucy.lawless@example.com')
        end
      end
    end
  end

  describe '.create_user' do
    context 'with a valid payload' do
      it 'creates a user' do
        VCR.use_cassette 'user_management/create_user_valid' do
          user = described_class.create_user(
            email: 'foo@example.com',
            first_name: 'Foo',
            last_name: 'Bar',
            email_verified: true,
          )

          expect(user.first_name).to eq('Foo')
          expect(user.last_name).to eq('Bar')
          expect(user.email).to eq('foo@example.com')
        end
      end

      context 'with an invalid payload' do
        it 'returns an error' do
          VCR.use_cassette 'user_management/create_user_invalid' do
            expect do
              described_class.create_user(email: '')
            end.to raise_error(
              WorkOS::UnprocessableEntityError,
              /email_string_required/,
            )
          end
        end
      end
    end
  end

  describe '.update_user' do
    context 'with a valid payload' do
      it 'update_user a user' do
        VCR.use_cassette 'user_management/update_user/valid' do
          user = described_class.update_user(
            id: 'user_01H7TVSKS45SDHN5V9XPSM6H44',
            first_name: 'Jane',
            last_name: 'Doe',
            email_verified: false,
          )
          expect(user.first_name).to eq('Jane')
          expect(user.last_name).to eq('Doe')
          expect(user.email_verified).to eq(false)
        end
      end

      context 'with an invalid payload' do
        it 'returns an error' do
          VCR.use_cassette 'user_management/update_user/invalid' do
            expect do
              described_class.update_user(id: 'invalid')
            end.to raise_error(WorkOS::NotFoundError, /User not found/)
          end
        end
      end
    end
  end

  describe '.delete_user' do
    context 'with a valid id' do
      it 'returns true' do
        VCR.use_cassette('user_management/delete_user/valid') do
          response = WorkOS::UserManagement.delete_user(
            id: 'user_01H7WRJBPAAHX1BYRQHEK7QC4A',
          )

          expect(response).to be(true)
        end
      end
    end

    context 'with an invalid id' do
      it 'raises an error' do
        VCR.use_cassette('user_management/delete_user/invalid') do
          expect do
            WorkOS::UserManagement.delete_user(id: 'invalid')
          end.to raise_error(WorkOS::NotFoundError, /User not found/)
        end
      end
    end
  end

  describe '.authenticate_with_password' do
    context 'with a valid password' do
      it 'returns user' do
        VCR.use_cassette('user_management/authenticate_with_password/valid', tag: :token) do
          authentication_response = WorkOS::UserManagement.authenticate_with_password(
            email: 'test@workos.app',
            password: '7YtYic00VWcXatPb',
            client_id: 'client_123',
            ip_address: '200.240.210.16',
            user_agent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Chrome/108.0.0.0 Safari/537.36',
          )
          expect(authentication_response.user.id).to eq('user_01H7TVSKS45SDHN5V9XPSM6H44')
        end
      end
    end

    context 'with an invalid user' do
      it 'raises an error' do
        VCR.use_cassette('user_management/authenticate_with_password/invalid') do
          expect do
            WorkOS::UserManagement.authenticate_with_password(
              email: 'invalid@workos.app',
              password: 'invalid',
              client_id: 'client_123',
              ip_address: '200.240.210.16',
              user_agent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Chrome/108.0.0.0 Safari/537.36',
            )
          end.to raise_error(WorkOS::NotFoundError, /User not found/)
        end
      end
    end
  end

  describe '.authenticate_with_code' do
    context 'with a valid code' do
      it 'returns user' do
        VCR.use_cassette('user_management/authenticate_with_code/valid') do
          authentication_response = WorkOS::UserManagement.authenticate_with_code(
            code: '01H93ZZHA0JBHFJH9RR11S83YN',
            client_id: 'client_123',
            ip_address: '200.240.210.16',
            user_agent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Chrome/108.0.0.0 Safari/537.36',
          )
          expect(authentication_response.user.id).to eq('user_01H93ZY4F80YZRRS6N59Z2HFVS')
          expect(authentication_response.access_token).to eq('<ACCESS_TOKEN>')
          expect(authentication_response.refresh_token).to eq('<REFRESH_TOKEN>')
        end
      end

      context 'when the user is being impersonated' do
        it 'contains the impersonator metadata' do
          VCR.use_cassette('user_management/authenticate_with_code/valid_with_impersonator') do
            authentication_response = WorkOS::UserManagement.authenticate_with_code(
              code: '01HRX85ATQB2MN40K4FZ9C2HFR',
              client_id: 'client_01GS91XFB2YPR1C0NR5SH758Q0',
            )

            expect(authentication_response.impersonator).to have_attributes(
              email: 'admin@foocorp.com',
              reason: 'For testing.',
            )
          end
        end
      end
    end

    context 'with an invalid code' do
      it 'raises an error' do
        VCR.use_cassette('user_management/authenticate_with_code/invalid') do
          expect do
            WorkOS::UserManagement.authenticate_with_code(
              code: 'invalid',
              client_id: 'client_123',
              ip_address: '200.240.210.16',
              user_agent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Chrome/108.0.0.0 Safari/537.36',
            )
          end.to raise_error(WorkOS::InvalidRequestError, /Status 400/)
        end
      end
    end
  end

  describe '.authenticate_with_refresh_token' do
    context 'with a valid refresh_token' do
      it 'returns user' do
        VCR.use_cassette('user_management/authenticate_with_refresh_token/valid', tag: :token) do
          authentication_response = WorkOS::UserManagement.authenticate_with_refresh_token(
            refresh_token: 'some_refresh_token',
            client_id: 'client_123',
            ip_address: '200.240.210.16',
            user_agent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Chrome/108.0.0.0 Safari/537.36',
          )
          expect(authentication_response.access_token).to eq('<ACCESS_TOKEN>')
          expect(authentication_response.refresh_token).to eq('<REFRESH_TOKEN>')
        end
      end
    end

    context 'with an invalid refresh_token' do
      it 'raises an error' do
        VCR.use_cassette('user_management/authenticate_with_refresh_code/invalid', tag: :token) do
          expect do
            WorkOS::UserManagement.authenticate_with_refresh_token(
              refresh_token: 'invalid',
              client_id: 'client_123',
              ip_address: '200.240.210.16',
              user_agent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Chrome/108.0.0.0 Safari/537.36',
            )
          end.to raise_error(WorkOS::InvalidRequestError, /Status 400/)
        end
      end
    end
  end

  describe '.authenticate_with_magic_auth' do
    context 'with a valid code' do
      it 'returns user' do
        VCR.use_cassette('user_management/authenticate_with_magic_auth/valid', tag: :token) do
          authentication_response = WorkOS::UserManagement.authenticate_with_magic_auth(
            code: '452079',
            client_id: 'project_01EGKAEB7G5N88E83MF99J785F',
            email: 'test@workos.com',
            ip_address: '200.240.210.16',
            user_agent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Chrome/108.0.0.0 Safari/537.36',
          )
          expect(authentication_response.user.id).to eq('user_01H93WD0R0KWF8Q7BK02C0RPYJ')
        end
      end
    end

    context 'with an invalid code' do
      it 'returns an error' do
        VCR.use_cassette('user_management/authenticate_with_magic_auth/invalid', tag: :token) do
          expect do
            WorkOS::UserManagement.authenticate_with_magic_auth(
              code: 'invalid',
              client_id: 'client_123',
              email: 'test@workos.com',
            )
          end.to raise_error(WorkOS::NotFoundError, /User not found/)
        end
      end
    end
  end

  describe '.authenticate_with_organization_selection' do
    context 'with a valid code' do
      it 'returns user' do
        VCR.use_cassette('user_management/authenticate_with_organization_selection/valid', tag: :token) do
          authentication_response = WorkOS::UserManagement.authenticate_with_organization_selection(
            client_id: 'project_01EGKAEB7G5N88E83MF99J785F',
            organization_id: 'org_01H5JQDV7R7ATEYZDEG0W5PRYS',
            pending_authentication_token: 'pending_authentication_token_1234',
            ip_address: '200.240.210.16',
            user_agent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Chrome/108.0.0.0 Safari/537.36',
          )
          expect(authentication_response.user.id).to eq('user_01H93WD0R0KWF8Q7BK02C0RPYJ')
          expect(authentication_response.organization_id).to eq('org_01H5JQDV7R7ATEYZDEG0W5PRYS')
        end
      end
    end

    context 'with an invalid token' do
      it 'returns an error' do
        VCR.use_cassette('user_management/authenticate_with_organization_selection/invalid', tag: :token) do
          expect do
            WorkOS::UserManagement.authenticate_with_organization_selection(
              organization_id: 'invalid_org_id',
              client_id: 'project_01EGKAEB7G5N88E83MF99J785F',
              pending_authentication_token: 'pending_authentication_token_1234',
            )
          end.to raise_error(WorkOS::InvalidRequestError, /Status 400/)
        end
      end
    end
  end

  describe '.authenticate_with_totp' do
    context 'with a valid code' do
      it 'returns user' do
        VCR.use_cassette('user_management/authenticate_with_totp/valid', tag: :token) do
          authentication_response = WorkOS::UserManagement.authenticate_with_totp(
            code: '01H93ZZHA0JBHFJH9RR11S83YN',
            client_id: 'client_123',
            pending_authentication_token: 'pending_authentication_token_1234',
            authentication_challenge_id: 'authentication_challenge_id',
            ip_address: '200.240.210.16',
            user_agent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Chrome/108.0.0.0 Safari/537.36',
          )
          expect(authentication_response.user.id).to eq('user_01H93ZY4F80YZRRS6N59Z2HFVS')
        end
      end
    end

    context 'with an invalid code' do
      it 'raises an error' do
        VCR.use_cassette('user_management/authenticate_with_totp/invalid', tag: :token) do
          expect do
            WorkOS::UserManagement.authenticate_with_totp(
              code: 'invalid',
              client_id: 'client_123',
              pending_authentication_token: 'pending_authentication_token_1234',
              authentication_challenge_id: 'authentication_challenge_id',
              ip_address: '200.240.210.16',
              user_agent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Chrome/108.0.0.0 Safari/537.36',
            )
          end.to raise_error(WorkOS::InvalidRequestError, /Status 400/)
        end
      end
    end
  end

  describe '.authenticate_with_email_verification' do
    context 'with a valid code' do
      it 'returns user' do
        VCR.use_cassette('user_management/authenticate_with_email_verification/valid', tag: :token) do
          authentication_response = WorkOS::UserManagement.authenticate_with_email_verification(
            code: '01H93ZZHA0JBHFJH9RR11S83YN',
            client_id: 'client_123',
            pending_authentication_token: 'pending_authentication_token_1234',
            ip_address: '200.240.210.16',
            user_agent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Chrome/108.0.0.0 Safari/537.36',
          )
          expect(authentication_response.user.id).to eq('user_01H93ZY4F80YZRRS6N59Z2HFVS')
        end
      end
    end

    context 'with an invalid code' do
      it 'raises an error' do
        VCR.use_cassette('user_management/authenticate_with_email_verification/invalid', tag: :token) do
          expect do
            WorkOS::UserManagement.authenticate_with_email_verification(
              code: 'invalid',
              client_id: 'client_123',
              pending_authentication_token: 'pending_authentication_token_1234',
              ip_address: '200.240.210.16',
              user_agent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Chrome/108.0.0.0 Safari/537.36',
            )
          end.to raise_error(WorkOS::InvalidRequestError, /Status 400/)
        end
      end
    end
  end

  describe '.get_magic_auth' do
    context 'with a valid id' do
      it 'returns a magic_auth object' do
        VCR.use_cassette 'user_management/get_magic_auth/valid' do
          magic_auth = described_class.get_magic_auth(
            id: 'magic_auth_01HWXVEWWSMR5HS8M6FBGMBJJ9',
          )

          expect(magic_auth.id.instance_of?(String))
          expect(magic_auth.instance_of?(WorkOS::MagicAuth))
        end
      end
    end

    context 'with an invalid id' do
      it 'raises an error' do
        VCR.use_cassette('user_management/get_magic_auth/invalid') do
          expect do
            WorkOS::UserManagement.get_magic_auth(id: 'invalid')
          end.to raise_error(WorkOS::NotFoundError, /MagicAuth not found/)
        end
      end
    end
  end

  describe '.create_magic_auth' do
    context 'with valid payload' do
      it 'creates a magic_auth' do
        VCR.use_cassette 'user_management/create_magic_auth/valid' do
          magic_auth = described_class.create_magic_auth(
            email: 'test@workos.com',
          )

          expect(magic_auth.id).to eq('magic_auth_01HWXVEWWSMR5HS8M6FBGMBJJ9')
          expect(magic_auth.email).to eq('test@workos.com')
        end
      end
    end
  end

  describe '.send_magic_auth_code' do
    context 'with valid parameters' do
      it 'sends a magic link to the email address' do
        VCR.use_cassette 'user_management/send_magic_auth_code/valid' do
          described_class.send_magic_auth_code(
            email: 'test@gmail.com',
          )
        end
      end
    end
  end

  describe '.enroll_auth_factor' do
    context 'with a valid user_id and auth factor type' do
      it 'returns an auth factor and challenge' do
        VCR.use_cassette('user_management/enroll_auth_factor/valid') do
          authentication_response = WorkOS::UserManagement.enroll_auth_factor(
            user_id: 'user_01H7TVSKS45SDHN5V9XPSM6H44',
            type: 'totp',
            totp_secret: 'secret-test',
          )

          expect(authentication_response.authentication_factor.id).to eq('auth_factor_01H96FETXENNY99ARX0GRC804C')
          expect(authentication_response.authentication_challenge.id).to eq('auth_challenge_01H96FETXGTW1QMBSBT2T36PW0')
        end
      end
    end

    context 'with an incorrect user id' do
      it 'raises an error' do
        VCR.use_cassette('user_management/enroll_auth_factor/invalid') do
          expect do
            WorkOS::UserManagement.enroll_auth_factor(
              user_id: 'user_01H7TVSKS45SDHN5V9XPSM6H44',
              type: 'totp',
            )
          end.to raise_error(WorkOS::InvalidRequestError, /Status 400/)
        end
      end
    end

    context 'with an invalid auth factor type' do
      it 'raises an error' do
        expect do
          described_class.enroll_auth_factor(user_id: 'user_01H7TVSKS45SDHN5V9XPSM6H44',
                                             type: 'invalid-factor',)
        end.to raise_error(
          ArgumentError,
          'invalid-factor is not a valid value. `type` must be in ["totp"]',
        )
      end
    end
  end

  describe '.list_auth_factors' do
    context 'with a valid user_id' do
      it 'returns a list of auth factors' do
        VCR.use_cassette('user_management/list_auth_factors/valid') do
          authentication_response = WorkOS::UserManagement.list_auth_factors(
            user_id: 'user_01H7TVSKS45SDHN5V9XPSM6H44',
          )

          expect(authentication_response.data.first.id).to eq('auth_factor_01H96FETXENNY99ARX0GRC804C')
        end
      end
    end
    context 'with an incorrect user id' do
      it 'raises an error' do
        VCR.use_cassette('user_management/list_auth_factors/invalid') do
          expect do
            WorkOS::UserManagement.list_auth_factors(
              user_id: 'user_01H7TVSKS45SDHN5V9XPSM6H44',
            )
          end.to raise_error(WorkOS::InvalidRequestError, /Status 400/)
        end
      end
    end
  end

  describe '.get_email_verification' do
    context 'with a valid id' do
      it 'returns an email_verification object' do
        VCR.use_cassette 'user_management/get_email_verification/valid' do
          email_verification = described_class.get_email_verification(
            id: 'email_verification_01HYK9VKNJQ0MJDXEXQP0DA1VK',
          )

          expect(email_verification.id.instance_of?(String))
          expect(email_verification.instance_of?(WorkOS::EmailVerification))
        end
      end
    end

    context 'with an invalid id' do
      it 'raises an error' do
        VCR.use_cassette('user_management/get_email_verification/invalid') do
          expect do
            WorkOS::UserManagement.get_email_verification(id: 'invalid')
          end.to raise_error(WorkOS::NotFoundError, /Email Verification not found/)
        end
      end
    end
  end

  describe '.send_verification_email' do
    context 'with valid parameters' do
      it 'sends an email to that user and the magic auth challenge' do
        VCR.use_cassette 'user_management/send_verification_email/valid' do
          verification_response = described_class.send_verification_email(
            user_id: 'user_01H93WD0R0KWF8Q7BK02C0RPYJ',
          )
          expect(verification_response.user.id).to eq('user_01H93WD0R0KWF8Q7BK02C0RPYJ')
        end
      end
    end

    context 'when the user does not exist' do
      it 'returns an error' do
        VCR.use_cassette 'user_management/send_verification_email/invalid' do
          expect do
            described_class.send_verification_email(
              user_id: 'bad_id',
            )
          end.to raise_error(WorkOS::NotFoundError, /User not found/)
        end
      end
    end
  end

  describe '.verify_email' do
    context 'with valid parameters' do
      it 'verifies the email and returns the user' do
        VCR.use_cassette 'user_management/verify_email/valid' do
          verify_response = described_class.verify_email(
            code: '333495',
            user_id: 'user_01H968BR1R84DSPYS9QR5PM6RZ',
          )

          expect(verify_response.user.id).to eq('user_01H968BR1R84DSPYS9QR5PM6RZ')
        end
      end
    end

    context 'with invalid parameters' do
      context 'when the id does not exist' do
        it 'raises an error' do
          VCR.use_cassette 'user_management/verify_email/invalid_magic_auth_challenge' do
            expect do
              described_class.verify_email(
                code: '659770',
                user_id: 'bad_id',
              )
            end.to raise_error(WorkOS::NotFoundError, /User not found/)
          end
        end
      end

      context 'when the code is incorrect' do
        it 'raises an error' do
          VCR.use_cassette 'user_management/verify_email/invalid_code' do
            expect do
              described_class.verify_email(
                code: '000000',
                user_id: 'user_01H93WD0R0KWF8Q7BK02C0RPYJ',
              )
            end.to raise_error(WorkOS::InvalidRequestError, /Email verification code is incorrect/)
          end
        end
      end
    end
  end

  describe '.get_password_reset' do
    context 'with a valid id' do
      it 'returns a password_reset object' do
        VCR.use_cassette 'user_management/get_password_reset/valid' do
          password_reset = described_class.get_password_reset(
            id: 'password_reset_01HYKA8DTF8TW5YD30MF0ZXZKT',
          )

          expect(password_reset.id.instance_of?(String))
          expect(password_reset.instance_of?(WorkOS::PasswordReset))
        end
      end
    end

    context 'with an invalid id' do
      it 'raises an error' do
        VCR.use_cassette('user_management/get_password_reset/invalid') do
          expect do
            WorkOS::UserManagement.get_password_reset(id: 'invalid')
          end.to raise_error(WorkOS::NotFoundError, /Password Reset not found/)
        end
      end
    end
  end

  describe '.create_password_reset' do
    context 'with valid payload' do
      it 'creates a password_reset object' do
        VCR.use_cassette 'user_management/create_password_reset/valid' do
          password_reset = described_class.create_password_reset(
            email: 'test@workos.com',
          )

          expect(password_reset.id).to eq('password_reset_01HYKA8DTF8TW5YD30MF0ZXZKT')
          expect(password_reset.email).to eq('test@workos.com')
        end
      end
    end
  end

  describe '.send_password_reset_email' do
    context 'with a valid payload' do
      it 'sends a password reset email' do
        VCR.use_cassette 'user_management/send_password_reset_email/valid' do
          response = described_class.send_password_reset_email(
            email: 'lucy.lawless@example.com',
            password_reset_url: 'https://example.com/reset',
          )

          expect(response).to be(true)
        end
      end
    end

    context 'with an invalid payload' do
      it 'returns an error' do
        VCR.use_cassette 'user_management/send_password_reset_email/invalid' do
          expect do
            described_class.send_password_reset_email(
              email: 'foo@bar.com',
              password_reset_url: '',
            )
          end.to raise_error(
            WorkOS::UnprocessableEntityError,
            /password_reset_url_string_required/,
          )
        end
      end
    end
  end

  describe '.reset_password' do
    context 'with a valid payload' do
      it 'resets the password and returns the user' do
        VCR.use_cassette 'user_management/reset_password/valid' do
          user = described_class.reset_password(
            token: 'eEgAgvAE0blvU1zWV3yWVAD22',
            new_password: 'very_cool_new_pa$$word',
          )

          expect(user.email).to eq('lucy.lawless@example.com')
        end
      end
    end

    context 'with an invalid payload' do
      it 'returns an error' do
        VCR.use_cassette 'user_management/reset_password/invalid' do
          expect do
            described_class.reset_password(
              token: 'bogus_token',
              new_password: 'new_password',
            )
          end.to raise_error(
            WorkOS::NotFoundError,
            /Could not locate user with provided token/,
          )
        end
      end
    end
  end

  describe '.get_organization_membership' do
    context 'with a valid id' do
      it 'returns a organization membership' do
        VCR.use_cassette 'user_management/get_organization_membership' do
          organization_membership = described_class.get_organization_membership(
            id: 'om_01H5JQDV7R7ATEYZDEG0W5PRYS',
          )

          expect(organization_membership.id.instance_of?(String))
          expect(organization_membership.instance_of?(WorkOS::OrganizationMembership))
        end
      end
    end

    context 'with an invalid id' do
      it 'returns an error' do
        expect do
          described_class.get_organization_membership(
            id: 'invalid_organization_membership_id',
          ).to raise_error(WorkOS::APIError)
        end
      end
    end
  end

  describe '.list_organization_memberships' do
    context 'with no options' do
      it 'returns a list of users' do
        expected_metadata = {
          'after' => nil,
          'before' => 'before-id',
        }

        VCR.use_cassette 'user_management/list_organization_memberships/no_options' do
          organization_memberships = described_class.list_organization_memberships

          expect(organization_memberships.data.size).to eq(2)
          expect(organization_memberships.list_metadata).to eq(expected_metadata)
        end
      end
    end

    context 'with options' do
      it 'returns a list of matching users' do
        request_args = [
          '/user_management/organization_memberships?user_id=user_01H5JQDV7R7ATEYZDEG0W5PRYS&'\
          'order=desc&limit=5',
          'Content-Type' => 'application/json'
        ]

        expected_request = Net::HTTP::Get.new(*request_args)

        expect(Net::HTTP::Get).to receive(:new).with(*request_args).
          and_return(expected_request)

        VCR.use_cassette 'user_management/list_organization_memberships/with_options' do
          organization_memberships = described_class.list_organization_memberships(
            user_id: 'user_01H5JQDV7R7ATEYZDEG0W5PRYS',
            order: 'desc',
            limit: '5',
          )

          expect(organization_memberships.data.size).to eq(1)
          expect(organization_memberships.data[0].user_id).to eq('user_01H5JQDV7R7ATEYZDEG0W5PRYS')
        end
      end
    end

    context 'with statuses option' do
      it 'returns a list of matching users' do
        request_args = [
          '/user_management/organization_memberships?user_id=user_01HXYSZBKQE2N3NHBKZHDP1X5X&'\
          'statuses=active&statuses=inactive&order=desc&limit=5',
          'Content-Type' => 'application/json'
        ]

        expected_request = Net::HTTP::Get.new(*request_args)

        expect(Net::HTTP::Get).to receive(:new).with(*request_args).
          and_return(expected_request)

        VCR.use_cassette 'user_management/list_organization_memberships/with_statuses_option' do
          organization_memberships = described_class.list_organization_memberships(
            user_id: 'user_01HXYSZBKQE2N3NHBKZHDP1X5X',
            statuses: %w[active inactive],
            order: 'desc',
            limit: '5',
          )

          expect(organization_memberships.data.size).to eq(1)
          expect(organization_memberships.data[0].user_id).to eq('user_01HXYSZBKQE2N3NHBKZHDP1X5X')
        end
      end
    end
  end

  describe '.create_organization_membership' do
    context 'with a valid payload' do
      it 'creates an organization membership' do
        VCR.use_cassette 'user_management/create_organization_membership/valid' do
          organization_membership = described_class.create_organization_membership(
            user_id: 'user_01H5JQDV7R7ATEYZDEG0W5PRYS',
            organization_id: 'org_01H5JQDV7R7ATEYZDEG0W5PRYS',
          )

          expect(organization_membership.organization_id).to eq('organization_01H5JQDV7R7ATEYZDEG0W5PRYS')
          expect(organization_membership.user_id).to eq('user_01H5JQDV7R7ATEYZDEG0W5PRYS')
          expect(organization_membership.role).to eq({ slug: 'member' })
        end
      end
    end

    context 'with an invalid payload' do
      it 'returns an error' do
        VCR.use_cassette 'user_management/create_organization_membership/invalid' do
          expect do
            described_class.create_organization_membership(user_id: '', organization_id: '')
          end.to raise_error(
            WorkOS::UnprocessableEntityError,
            /user_id_string_required/,
          )
        end
      end
    end

    context 'with a role slug' do
      it 'creates an organization with the given role slug ' do
        VCR.use_cassette 'user_management/create_organization_membership/valid' do
          organization_membership = described_class.create_organization_membership(
            user_id: 'user_01H5JQDV7R7ATEYZDEG0W5PRYS',
            organization_id: 'org_01H5JQDV7R7ATEYZDEG0W5PRYS',
            role_slug: 'member',
          )

          expect(organization_membership.organization_id).to eq('organization_01H5JQDV7R7ATEYZDEG0W5PRYS')
          expect(organization_membership.user_id).to eq('user_01H5JQDV7R7ATEYZDEG0W5PRYS')
          expect(organization_membership.role).to eq({ slug: 'member' })
        end
      end
    end
  end

  describe '.delete_organization_membership' do
    context 'with a valid id' do
      it 'returns true' do
        VCR.use_cassette('user_management/delete_organization_membership/valid') do
          response = WorkOS::UserManagement.delete_organization_membership(
            id: 'om_01H5JQDV7R7ATEYZDEG0W5PRYS',
          )

          expect(response).to be(true)
        end
      end
    end

    context 'with an invalid id' do
      it 'raises an error' do
        VCR.use_cassette('user_management/delete_organization_membership/invalid') do
          expect do
            WorkOS::UserManagement.delete_organization_membership(id: 'invalid')
          end.to raise_error(WorkOS::NotFoundError, /Organization Membership not found/)
        end
      end
    end
  end

  describe '.deactivate_organization_membership' do
    context 'with a valid id' do
      it 'returns a organization membership' do
        VCR.use_cassette 'user_management/deactivate_organization_membership' do
          organization_membership = described_class.deactivate_organization_membership(
            id: 'om_01HXYT0G3H5QG9YTSHSHFZQE6D',
          )

          expect(organization_membership.id.instance_of?(String))
          expect(organization_membership.instance_of?(WorkOS::OrganizationMembership))
        end
      end
    end

    context 'with an invalid id' do
      it 'returns an error' do
        expect do
          described_class.deactivate_organization_membership(
            id: 'invalid_organization_membership_id',
          ).to raise_error(WorkOS::APIError)
        end
      end
    end
  end

  describe '.reactivate_organization_membership' do
    context 'with a valid id' do
      it 'returns a organization membership' do
        VCR.use_cassette 'user_management/reactivate_organization_membership' do
          organization_membership = described_class.reactivate_organization_membership(
            id: 'om_01HXYT0G3H5QG9YTSHSHFZQE6D',
          )

          expect(organization_membership.id.instance_of?(String))
          expect(organization_membership.instance_of?(WorkOS::OrganizationMembership))
        end
      end
    end

    context 'with an invalid id' do
      it 'returns an error' do
        expect do
          described_class.reactivate_organization_membership(
            id: 'invalid_organization_membership_id',
          ).to raise_error(WorkOS::APIError)
        end
      end
    end
  end

  describe '.get_invitation' do
    context 'with a valid id' do
      it 'returns an invitation' do
        VCR.use_cassette 'user_management/get_invitation/valid' do
          invitation = described_class.get_invitation(
            id: 'invitation_01H5JQDV7R7ATEYZDEG0W5PRYS',
          )

          expect(invitation.id.instance_of?(String))
          expect(invitation.instance_of?(WorkOS::Invitation))
        end
      end
    end

    context 'with an invalid id' do
      it 'raises an error' do
        VCR.use_cassette('user_management/get_invitation/invalid') do
          expect do
            WorkOS::UserManagement.get_invitation(id: 'invalid')
          end.to raise_error(WorkOS::NotFoundError, /Invitation not found/)
        end
      end
    end
  end

  describe '.find_invitation_by_token' do
    context 'with a valid id' do
      it 'returns an invitation' do
        VCR.use_cassette 'user_management/find_invitation_by_token/valid' do
          invitation = described_class.find_invitation_by_token(
            token: 'iUV3XbYajpJlbpw1Qt3ZKlaKx',
          )

          expect(invitation.id.instance_of?(String))
          expect(invitation.instance_of?(WorkOS::Invitation))
        end
      end
    end

    context 'with an invalid id' do
      it 'raises an error' do
        VCR.use_cassette('user_management/find_invitation_by_token/invalid') do
          expect do
            WorkOS::UserManagement.find_invitation_by_token(token: 'invalid')
          end.to raise_error(WorkOS::NotFoundError, /Invitation not found/)
        end
      end
    end
  end

  describe '.list_invitations' do
    context 'with no options' do
      it 'returns invitations and metadata' do
        expected_metadata = {
          'after' => nil,
          'before' => 'before_id',
        }

        VCR.use_cassette 'user_management/list_invitations/with_no_options' do
          invitations = described_class.list_invitations

          expect(invitations.data.size).to eq(5)
          expect(invitations.list_metadata).to eq(expected_metadata)
        end
      end
    end

    context 'with organization_id option' do
      it 'forms the proper request to the API' do
        request_args = [
          '/user_management/invitations?organization_id=org_01H5JQDV7R7ATEYZDEG0W5PRYS&'\
          'order=desc',
          'Content-Type' => 'application/json'
        ]

        expected_request = Net::HTTP::Get.new(*request_args)

        expect(Net::HTTP::Get).to receive(:new).with(*request_args).
          and_return(expected_request)

        VCR.use_cassette 'user_management/list_invitations/with_organization_id' do
          invitations = described_class.list_invitations(
            organization_id: 'org_01H5JQDV7R7ATEYZDEG0W5PRYS',
          )

          expect(invitations.data.size).to eq(1)
          expect(invitations.data.first.organization_id).to eq(
            'org_01H5JQDV7R7ATEYZDEG0W5PRYS',
          )
        end
      end
    end

    context 'with limit option' do
      it 'forms the proper request to the API' do
        request_args = [
          '/user_management/invitations?limit=2&'\
          'order=desc',
          'Content-Type' => 'application/json'
        ]

        expected_request = Net::HTTP::Get.new(*request_args)

        expect(Net::HTTP::Get).to receive(:new).with(*request_args).
          and_return(expected_request)

        VCR.use_cassette 'user_management/list_invitations/with_limit' do
          invitations = described_class.list_invitations(
            limit: 2,
          )

          expect(invitations.data.size).to eq(3)
        end
      end
    end

    context 'with before option' do
      it 'forms the proper request to the API' do
        request_args = [
          '/user_management/invitations?before=invitation_01H5JQDV7R7ATEYZDEG0W5PRYS&'\
          'order=desc',
          'Content-Type' => 'application/json'
        ]

        expected_request = Net::HTTP::Get.new(*request_args)

        expect(Net::HTTP::Get).to receive(:new).with(*request_args).
          and_return(expected_request)

        VCR.use_cassette 'user_management/list_invitations/with_before' do
          invitations = described_class.list_invitations(
            before: 'invitation_01H5JQDV7R7ATEYZDEG0W5PRYS',
          )

          expect(invitations.data.size).to eq(2)
        end
      end
    end

    context 'with after option' do
      it 'forms the proper request to the API' do
        request_args = [
          '/user_management/invitations?after=invitation_01H5JQDV7R7ATEYZDEG0W5PRYS&'\
          'order=desc',
          'Content-Type' => 'application/json'
        ]

        expected_request = Net::HTTP::Get.new(*request_args)

        expect(Net::HTTP::Get).to receive(:new).with(*request_args).
          and_return(expected_request)

        VCR.use_cassette 'user_management/list_invitations/with_after' do
          invitations = described_class.list_invitations(
            after: 'invitation_01H5JQDV7R7ATEYZDEG0W5PRYS',
          )

          expect(invitations.data.size).to eq(2)
        end
      end
    end
  end

  describe '.send_invitation' do
    context 'with valid payload' do
      it 'sends an invitation' do
        VCR.use_cassette 'user_management/send_invitation/valid' do
          invitation = described_class.send_invitation(
            email: 'test@workos.com',
          )

          expect(invitation.id).to eq('invitation_01H5JQDV7R7ATEYZDEG0W5PRYS')
          expect(invitation.email).to eq('test@workos.com')
        end
      end
    end

    context 'with an invalid payload' do
      it 'returns an error' do
        VCR.use_cassette 'user_management/send_invitation/invalid' do
          expect do
            described_class.send_invitation(
              email: 'invalid@workos.com',
            )
          end.to raise_error(
            WorkOS::APIError,
            /An Invitation with the email invalid@workos.com already exists/,
          )
        end
      end
    end
  end

  describe '.revoke_invitation' do
    context 'with valid payload' do
      it 'revokes invitation' do
        VCR.use_cassette 'user_management/revoke_invitation/valid' do
          invitation = described_class.revoke_invitation(
            id: 'invitation_01H5JQDV7R7ATEYZDEG0W5PRYS',
          )

          expect(invitation.id).to eq('invitation_01H5JQDV7R7ATEYZDEG0W5PRYS')
          expect(invitation.email).to eq('test@workos.com')
        end
      end
    end

    context 'with an invalid payload' do
      it 'returns an error' do
        VCR.use_cassette 'user_management/revoke_invitation/invalid' do
          expect do
            described_class.revoke_invitation(
              id: 'invalid_id',
            )
          end.to raise_error(
            WorkOS::NotFoundError,
            /Invitation not found/,
          )
        end
      end
    end
  end

  describe '.revoke_session' do
    context 'with valid payload' do
      it 'revokes session' do
        VCR.use_cassette 'user_management/revoke_session/valid' do
          result = described_class.revoke_session(
            session_id: 'session_01HRX85ATNADY1GQ053AHRFFN6',
          )

          expect(result).to be true
        end
      end
    end

    context 'with a non-existant session' do
      it 'returns an error' do
        VCR.use_cassette 'user_management/revoke_session/not_found' do
          expect do
            described_class.revoke_session(
              session_id: 'session_01H5JQDV7R7ATEYZDEG0W5PRYS',
            )
          end.to raise_error(
            WorkOS::NotFoundError,
            /Session not found/,
          )
        end
      end
    end
  end
end
