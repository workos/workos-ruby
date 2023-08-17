# frozen_string_literal: true
# typed: false

describe WorkOS::UserManagement do
  it_behaves_like 'client'

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
end
