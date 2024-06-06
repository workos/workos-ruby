# frozen_string_literal: true

describe WorkOS::Client do
  describe '.client' do
    it 'returns a 400 error with appropriate fields' do
      VCR.use_cassette('user_management/authenticate_with_code/invalid') do
        expect do
          WorkOS::UserManagement.authenticate_with_code(
            code: 'invalid',
            client_id: 'client_123',
            ip_address: '200.240.210.16',
            user_agent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Chrome/108.0.0.0 Safari/537.36',
          )
        end.to raise_error do |error|
          expect(error).to be_a(WorkOS::InvalidRequestError)
          expect(error.error).not_to be_nil
          expect(error.error_description).not_to be_nil
          expect(error.data).not_to be_nil
        end
      end
    end

    it 'returns a 401 error with appropriate fields' do
      VCR.use_cassette('base/execute_request_unauthenticated') do
        expect do
          WorkOS::AuditLogs.create_event(
            organization: 'org_123',
            event: {},
          )
        end.to raise_error do |error|
          expect(error).to be_a(WorkOS::AuthenticationError)
          expect(error.message).not_to be_nil
        end
      end
    end

    it 'returns a 404 error with appropriate fields' do
      VCR.use_cassette('user_management/get_email_verification/invalid') do
        expect do
          WorkOS::UserManagement.get_email_verification(
            id: 'invalid',
          )
        end.to raise_error do |error|
          expect(error).to be_a(WorkOS::NotFoundError)
          expect(error.message).not_to be_nil
        end
      end
    end

    it 'returns a 422 error with appropriate fields' do
      VCR.use_cassette('user_management/create_user_invalid') do
        expect do
          WorkOS::UserManagement.create_user(
            email: 'invalid',
          )
        end.to raise_error do |error|
          expect(error).to be_a(WorkOS::UnprocessableEntityError)
          expect(error.message).not_to be_nil
          expect(error.errors).not_to be_nil
          expect(error.code).not_to be_nil
        end
      end
    end
  end
end