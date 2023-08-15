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
end
