# frozen_string_literal: true
# typed: false

describe WorkOS::DirectoryUser do
  # rubocop:disable Layout/LineLength
  describe '.get_primary_email' do
    context 'with one primary email' do
      it 'returns the primary email' do
        user = WorkOS::DirectoryUser.new('{"object":"directory_user","id":"directory_user_01FAZYNPC8M0HRYTKFP2GNX852","directory_id":"directory_01FAZYMST676QMTFN1DDJZZX87","idp_id":"6092c280a3f1e19ef6d8cef8","username":"logan@workos.com","emails":[{"primary":true,"value":"logan@workos.com"}, {"primary":false,"value":"logan@gmail.com"}],"first_name":"Logan","last_name":"Gingerich","job_title":"Developer Success Engineer","state":"active","raw_attributes":{},"custom_attributes":{},"groups":[],"created_at":"2022-05-13T17:45:31.732Z", "updated_at":"2022-07-13T17:45:42.618Z"}')
        expect(user.primary_email).to eq('logan@workos.com')
      end
    end

    context 'with multiple primary emails' do
      it 'returns the first email marked as primary' do
        user = WorkOS::DirectoryUser.new('{"object":"directory_user","id":"directory_user_01FAZYNPC8M0HRYTKFP2GNX852","directory_id":"directory_01FAZYMST676QMTFN1DDJZZX87","idp_id":"6092c280a3f1e19ef6d8cef8","username":"logan@workos.com","emails":[{"primary":true,"value":"logan@workos.com"}, {"primary":true,"value":"logan@gmail.com"}],"first_name":"Logan","last_name":"Gingerich","job_title":"Developer Success Engineer","state":"active","raw_attributes":{},"custom_attributes":{},"groups":[],"created_at":"2022-05-13T17:45:31.732Z", "updated_at":"2022-07-13T17:45:42.618Z"}')
        expect(user.primary_email).to eq('logan@workos.com')
      end
    end

    context 'with no primary emails' do
      it 'returns nil' do
        user = WorkOS::DirectoryUser.new('{"object":"directory_user","id":"directory_user_01FAZYNPC8M0HRYTKFP2GNX852","directory_id":"directory_01FAZYMST676QMTFN1DDJZZX87","idp_id":"6092c280a3f1e19ef6d8cef8","username":"logan@workos.com","emails":[{"primary":false,"value":"logan@gmail.com"}],"first_name":"Logan","last_name":"Gingerich","job_title":"Developer Success Engineer","state":"active","raw_attributes":{},"custom_attributes":{},"groups":[],"created_at":"2022-05-13T17:45:31.732Z","updated_at":"2022-07-13T17:45:42.618Z"}')
        expect(user.primary_email).to eq(nil)
      end
    end

    context 'with an empty email array' do
      it 'returns nil' do
        user = WorkOS::DirectoryUser.new('{"object":"directory_user","id":"directory_user_01FAZYNPC8M0HRYTKFP2GNX852","directory_id":"directory_01FAZYMST676QMTFN1DDJZZX87","idp_id":"6092c280a3f1e19ef6d8cef8","username":"logan@workos.com","emails":[],"first_name":"Logan","last_name":"Gingerich","job_title":"Developer Success Engineer","state":"active","raw_attributes":{},"custom_attributes":{},"groups":[],"created_at":"2022-05-13T17:45:31.732Z","updated_at":"2022-07-13T17:45:42.618Z"}')
        expect(user.primary_email).to eq(nil)
      end
    end
  end
  # rubocop:enable Layout/LineLength
end
