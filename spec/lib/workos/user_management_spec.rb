# frozen_string_literal: true
# typed: false

describe WorkOS::UserManagement do
  it_behaves_like 'client'

  describe '.create_password_reset_challenge' do
    context 'with a valid payload' do
      it 'creates a password reset challenge' do
        VCR.use_cassette 'user_management/create_password_reset_challenge/valid' do
          user_and_token = described_class.create_password_reset_challenge(
            email: 'lucy.lawless@example.com',
            password_reset_url: 'https://example.com/reset',
          )

          expect(user_and_token.user.email).to eq('lucy.lawless@example.com')
          expect(user_and_token.token.instance_of?(String))
        end
      end
    end

    context 'with an invalid payload' do
      it 'returns an error' do
        VCR.use_cassette 'user_management/create_password_reset_challenge/invalid' do
          expect do
            described_class.create_password_reset_challenge(
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

  describe '.add_user_to_organization' do
    context 'with valid paramters' do
      it 'adds the user to the organization' do
        VCR.use_cassette 'user_management/add_user_to_organization_valid' do
          user = described_class.add_user_to_organization(
            id: 'user_01H7WRJBPAAHX1BYRQHEK7QC4A',
            organization_id: 'org_01GEQJ8PKE4WH1Q09RSC8CCVJ1',
          )

          expect(user.id).to eq('user_01H7WRJBPAAHX1BYRQHEK7QC4A')
        end
      end
    end

    context 'with invalid parameters' do
      it 'returns an error' do
        VCR.use_cassette 'user_management/add_user_to_organization_invalid' do
          expect do
            described_class.add_user_to_organization(
              id: 'bad_id',
              organization_id: 'bad_id',
            )
          end.to raise_error(WorkOS::APIError, /User not found/)
        end
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
          '/users?email=lucy.lawless%40example.com&type=unmanaged&order=desc&limit=5',
          'Content-Type' => 'application/json'
        ]

        expected_request = Net::HTTP::Get.new(*request_args)

        expect(Net::HTTP::Get).to receive(:new).with(*request_args).
          and_return(expected_request)

        VCR.use_cassette 'user_management/list_users/with_options' do
          users = described_class.list_users(
            email: 'lucy.lawless@example.com',
            type: 'unmanaged',
            order: 'desc',
            limit: '5',
          )

          expect(users.data.size).to eq(1)
          expect(users.data[0].email).to eq('lucy.lawless@example.com')
        end
      end
    end
  end

  describe '.remove_user_from_organization' do
    context 'with valid paramters' do
      it 'removes the user from the organization' do
        VCR.use_cassette 'user_management/remove_user_from_organization_valid' do
          user = described_class.remove_user_from_organization(
            id: 'user_01H7WRJBPAAHX1BYRQHEK7QC4A',
            organization_id: 'org_01GEQJ8PKE4WH1Q09RSC8CCVJ1',
          )

          expect(user.id).to eq('user_01H7WRJBPAAHX1BYRQHEK7QC4A')
        end
      end
    end

    context 'with invalid parameters' do
      it 'returns an error' do
        VCR.use_cassette 'user_management/remove_user_from_organization_invalid' do
          expect do
            described_class.remove_user_from_organization(
              id: 'bad_id',
              organization_id: 'bad_id',
            )
          end.to raise_error(WorkOS::APIError, /UserOrganizationMembership not found/)
        end
      end
    end
  end

  describe '.send_magic_auth_code' do
    context 'with valid parameters' do
      it 'sends a magic link to the email address' do
        VCR.use_cassette 'user_management/send_magic_auth_code/valid' do
          magic_auth_challenge = described_class.send_magic_auth_code(
            email_address: 'lucy.lawless@example.com',
          )

          expect(magic_auth_challenge.id).to eq('auth_challenge_01H8D0ZVH77EEYMDJJRRT8A8AC')
        end
      end
    end
  end

  describe '.send_verification_email' do
    context 'with valid paramters' do
      it 'sends an email to that user and returns it' do
        VCR.use_cassette 'user_management/send_verification_email/valid' do
          user = described_class.send_verification_email(
            id: 'user_01H7WRJBPAAHX1BYRQHEK7QC4A',
          )

          expect(user.id).to eq('user_01H7WRJBPAAHX1BYRQHEK7QC4A')
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
end
