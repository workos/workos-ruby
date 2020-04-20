# frozen_string_literal: true
# typed: false

describe WorkOS::DirectorySync do
  before(:all) do
    WorkOS.key = 'key'
  end

  after(:all) do
    WorkOS.key = nil
  end

  describe '.list_directories' do
    context 'with no options' do
      it 'returns directories' do
        VCR.use_cassette('directory_sync/list_directories') do
          directories = WorkOS::DirectorySync.list_directories
          expect(directories.size).to eq(1)
        end
      end
    end

    context 'with domain option' do
      it 'returns directories' do
        VCR.use_cassette('directory_sync/list_directories_with_domain_param') do
          directories = WorkOS::DirectorySync.list_directories(
            domain: 'foo-corp.com',
          )

          expect(directories.first['domain']).to eq('foo-corp.com')
        end
      end
    end
  end

  describe '.list_groups' do
    context 'with no options' do
      it 'returns groups' do
        VCR.use_cassette('directory_sync/list_groups') do
          expect {
            WorkOS::DirectorySync.list_groups
          }.to raise_error(
            WorkOS::InvalidRequestError,
            /Status 422, Validation failed/,
          )
        end
      end
    end

    context 'with directory option' do
      it 'returns groups' do
        VCR.use_cassette('directory_sync/list_groups_with_directory_param') do
          groups = WorkOS::DirectorySync.list_groups(
            directory: 'directory_edp_01E64QQVQTCB0DECJ9CFNXEWDW',
          )

          expect(groups.size).to eq(2)
          expect(groups.first['name']).to eq('Walrus')
        end
      end
    end
  end

  describe '.list_users' do
    context 'with no options' do
      it 'returns users' do
        VCR.use_cassette('directory_sync/list_users') do
          expect {
            WorkOS::DirectorySync.list_users
          }.to raise_error(
            WorkOS::InvalidRequestError,
            /Status 422, Validation failed/,
          )
        end
      end
    end

    context 'with directory option' do
      it 'returns users' do
        VCR.use_cassette('directory_sync/list_users_with_directory_param') do
          users = WorkOS::DirectorySync.list_users(
            directory: 'directory_edp_01E64QQVQTCB0DECJ9CFNXEWDW',
          )

          expect(users.size).to eq(1)
          expect(users.first['last_name']).to eq('Tran')
        end
      end
    end
  end

  describe '.get_group' do
    context 'with valid id' do
      it 'returns a group' do
        VCR.use_cassette('directory_sync/get_group') do
          group = WorkOS::DirectorySync.get_group(
            'directory_grp_01E64QTDNS0EGJ0FMCVY9BWGZT',
          )

          expect(group['name']).to eq('Walrus')
        end
      end
    end

    context 'with invalid id' do
      it 'raises an error' do
        VCR.use_cassette('directory_sync/get_group_with_invalid_id') do
          expect {
            WorkOS::DirectorySync.get_group('invalid')
          }.to raise_error(WorkOS::APIError)
        end
      end
    end
  end

  describe '.get_user' do
    context 'with valid id' do
      it 'returns a user' do
        VCR.use_cassette('directory_sync/get_user') do
          user = WorkOS::DirectorySync.get_user(
            'directory_usr_01E64QS50EAY48S0XJ1AA4WX4D',
          )

          expect(user['first_name']).to eq('Mark')
        end
      end
    end

    context 'with invalid id' do
      it 'raises an error' do
        VCR.use_cassette('directory_sync/get_user_with_invalid_id') do
          expect {
            WorkOS::DirectorySync.get_user('invalid')
          }.to raise_error(WorkOS::APIError)
        end
      end
    end
  end
end
