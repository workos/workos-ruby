# frozen_string_literal: true
# typed: false

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
          'Okta is not a valid value. `provider` must be in ["GoogleOAuth", "MicrosoftOAuth", "authkit"]',
        )
      end
    end
  end

  describe '.get_user' do
    context 'with a valid id' do
      it 'returns a user' do
        VCR.use_cassette 'user_management/get_user' do
          user = described_class.get_user(
            id: 'user_01H7TVSKS45SDHN5V9XPSM6H44',
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
          '/user_management/users?email=lucy.lawless%40example.com&order=desc&limit=5',
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
              WorkOS::InvalidRequestError,
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
            end.to raise_error(WorkOS::APIError, /User not found/)
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
          end.to raise_error(WorkOS::APIError, /User not found/)
        end
      end
    end
  end

  describe '.authenticate_with_password' do
    context 'with a valid password' do
      it 'returns user' do
        VCR.use_cassette('user_management/authenticate_with_password/valid') do
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
          end.to raise_error(WorkOS::APIError, /User not found/)
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

  describe '.authenticate_with_magic_auth' do
    context 'with a valid code' do
      it 'returns user' do
        VCR.use_cassette('user_management/authenticate_with_magic_auth/valid') do
          authentication_response = WorkOS::UserManagement.authenticate_with_magic_auth(
            code: '452079',
            client_id: 'project_01EGKAEB7G5N88E83MF99J785F',
            user_id: 'user_01H93WD0R0KWF8Q7BK02C0RPYJ',
            ip_address: '200.240.210.16',
            user_agent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Chrome/108.0.0.0 Safari/537.36',
          )
          expect(authentication_response.user.id).to eq('user_01H93WD0R0KWF8Q7BK02C0RPYJ')
        end
      end
    end

    context 'with an invalid code' do
      it 'returns an error' do
        VCR.use_cassette('user_management/authenticate_with_magic_auth/invalid') do
          expect do
            WorkOS::UserManagement.authenticate_with_magic_auth(
              code: 'invalid',
              client_id: 'client_123',
              user_id: 'user_01H93WD0R0KWF8Q7BK02C0RPY',
            )
          end.to raise_error(WorkOS::APIError, /User not found/)
        end
      end
    end
  end

  describe '.authenticate_with_totp' do
    context 'with a valid code' do
      it 'returns user' do
        VCR.use_cassette('user_management/authenticate_with_totp/valid') do
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
        VCR.use_cassette('user_management/authenticate_with_totp/invalid') do
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
        VCR.use_cassette('user_management/authenticate_with_email_verification/valid') do
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
        VCR.use_cassette('user_management/authenticate_with_email_verification/invalid') do
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

  describe '.send_magic_auth_code' do
    context 'with valid parameters' do
      it 'sends a magic link to the email address' do
        VCR.use_cassette 'user_management/send_magic_auth_code/valid' do
          magic_link_response = described_class.send_magic_auth_code(
            email: 'test@gmail.com',
          )
          expect(magic_link_response.user.id).to eq('user_01H93WD0R0KWF8Q7BK02C0RPYJ')
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

  describe '.send_verification_email' do
    context 'with valid parameters' do
      it 'sends an email to that user and the magic auth challenge' do
        VCR.use_cassette 'user_management/send_verification_email/valid' do
          verification_response = described_class.send_verification_email(
            id: 'user_01H93WD0R0KWF8Q7BK02C0RPYJ',
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
              id: 'bad_id',
            )
          end.to raise_error(WorkOS::APIError, /User not found/)
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
            end.to raise_error(WorkOS::APIError, /User not found/)
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
            WorkOS::InvalidRequestError,
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
            WorkOS::APIError,
            /Could not locate user with provided token/,
          )
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
          '/user_management/invitations?organization_id=org_01H5JQDV7R7ATEYZDEG0W5PRYS',
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
          '/user_management/invitations?limit=2',
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
          '/user_management/invitations?before=conn_01FA3WGCWPCCY1V2FGES2FDNP7',
          'Content-Type' => 'application/json'
        ]

        expected_request = Net::HTTP::Get.new(*request_args)

        expect(Net::HTTP::Get).to receive(:new).with(*request_args).
          and_return(expected_request)

        VCR.use_cassette 'user_management/list_invitations/with_before' do
          invitations = described_class.list_invitations(
            before: 'conn_01FA3WGCWPCCY1V2FGES2FDNP7',
          )

          expect(invitations.data.size).to eq(2)
        end
      end
    end

    context 'with after option' do
      it 'forms the proper request to the API' do
        request_args = [
          '/user_management/invitations?after=conn_01FA3WGCWPCCY1V2FGES2FDNP7',
          'Content-Type' => 'application/json'
        ]

        expected_request = Net::HTTP::Get.new(*request_args)

        expect(Net::HTTP::Get).to receive(:new).with(*request_args).
          and_return(expected_request)

        VCR.use_cassette 'user_management/list_invitations/with_after' do
          invitations = described_class.list_invitations(
            after: 'conn_01FA3WGCWPCCY1V2FGES2FDNP7',
          )

          expect(invitations.data.size).to eq(2)
        end
      end
    end
  end

  describe '.send_invitation' do
    # TODO: - Implement tests
  end

  describe '.revoke_invitation' do
    # TODO: - Implement tests
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
        end.to raise_error(WorkOS::APIError, /Invitation not found/)
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
        '/user_management/invitations?organization_id=org_01H5JQDV7R7ATEYZDEG0W5PRYS',
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
        '/user_management/invitations?limit=2',
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
        '/user_management/invitations?before=invitation_01H5JQDV7R7ATEYZDEG0W5PRYS',
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
        '/user_management/invitations?after=invitation_01H5JQDV7R7ATEYZDEG0W5PRYS',
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
          WorkOS::APIError,
          /Invitation not found/,
        )
      end
    end
  end
end
end
