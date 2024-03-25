# frozen_string_literal: true

describe WorkOS::Passwordless do
  it_behaves_like 'client'

  describe '.create_session' do
    context 'with valid options payload' do
      let(:valid_options) do
        {
          email: 'demo@workos-okta.com',
          type: 'MagicLink',
          redirect_uri: 'foo.com/auth/callback',
        }
      end

      it 'creates a session' do
        VCR.use_cassette('passwordless/create_session') do
          response = described_class.create_session(valid_options)

          expect(response.email).to eq 'demo@workos-okta.com'
        end
      end
    end

    context 'with invalid event payload' do
      let(:invalid_options) do
        {}
      end

      it 'raises an error' do
        VCR.use_cassette('passwordless/create_session_invalid') do
          expect do
            described_class.create_session(invalid_options)
          end.to raise_error(
            WorkOS::InvalidRequestError,
            /Status 422, Validation failed \(email: email must be a string; type: type must be a valid enum value\)/,
          )
        end
      end
    end
  end

  describe '.send_session' do
    context 'with valid session id' do
      let(:valid_options) do
        {
          email: 'demo@workos-okta.com',
          type: 'MagicLink',
        }
      end

      it 'send a session' do
        VCR.use_cassette('passwordless/send_session') do
          response = described_class.send_session(
            'passwordless_session_01EJC0F4KH42T11Y2DHPEB09BM',
          )

          expect(response['success']).to eq true
        end
      end
    end

    context 'with invalid session id' do
      it 'raises an error' do
        VCR.use_cassette('passwordless/send_session_invalid') do
          expect do
            described_class.send_session('session_123')
          end.to raise_error(
            WorkOS::InvalidRequestError,
            /Status 422, The passwordless session 'session_123' has expired or is invalid./,
          )
        end
      end
    end
  end
end
