# frozen_string_literal: true

describe WorkOS::Widgets do
  it_behaves_like 'client'

  describe '.get_token' do
    let(:organization_id) { 'org_01JCP9G67MNAH0KC4B72XZ67M7' }
    let(:user_id) { 'user_01JCP9H4SHS4N3J6XTKDT7JNPE' }

    describe 'with a valid organization_id and user_id and scopes' do
      it 'returns a widget token' do
        VCR.use_cassette 'widgets/get_token' do
          token = described_class.get_token(
            organization_id: organization_id,
            user_id: user_id,
            scopes: ['widgets:users-table:manage'],
          )

          expect(token).to start_with('eyJhbGciOiJSUzI1NiIsImtpZ')
        end
      end
    end

    describe 'with an invalid organization_id' do
      it 'raises an error' do
        VCR.use_cassette 'widgets/get_token_invalid_organization_id' do
          expect do
            described_class.get_token(
              organization_id: 'bogus-id',
              user_id: user_id,
              scopes: ['widgets:users-table:manage'],
            )
          end.to raise_error(
            WorkOS::NotFoundError,
            /Organization not found: 'bogus-id'/,
          )
        end
      end
    end

    describe 'with an invalid user_id' do
      it 'raises an error' do
        VCR.use_cassette 'widgets/get_token_invalid_user_id' do
          expect do
            described_class.get_token(
              organization_id: organization_id,
              user_id: 'bogus-id',
              scopes: ['widgets:users-table:manage'],
            )
          end.to raise_error(
            WorkOS::NotFoundError,
            /User not found: 'bogus-id'/,
          )
        end
      end
    end

    describe 'with invalid scopes' do
      it 'raises an error' do
        expect do
          described_class.get_token(
            organization_id: organization_id,
            user_id: user_id,
            scopes: ['bogus-scope'],
          )
        end.to raise_error(
          ArgumentError,
          /scopes contains an invalid value/,
        )
      end
    end
  end
end
