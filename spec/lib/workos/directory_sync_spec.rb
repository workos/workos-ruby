# frozen_string_literal: true
# typed: false

describe WorkOS::DirectorySync do
  describe '.list_directories' do
    context 'with no options' do
      it 'returns directories and metadata' do
        expected_metadata = {
          'after' => nil,
          'before' => 'before-id',
        }

        VCR.use_cassette 'directory_sync/list_directories/with_no_options' do
          directories = described_class.list_directories

          expect(directories.data.size).to eq(3)
          expect(directories.list_metadata).to eq(expected_metadata)
        end
      end
    end

    context 'with domain option' do
      it 'forms the proper request to the API' do
        request_args = [
          '/directories?domain=foo-corp.com',
          'Content-Type' => 'application/json'
        ]

        expected_request = Net::HTTP::Get.new(*request_args)

        expect(Net::HTTP::Get).to receive(:new).with(*request_args).
          and_return(expected_request)

        VCR.use_cassette 'directory_sync/list_directories/with_domain' do
          directories = described_class.list_directories(
            domain: 'foo-corp.com',
          )

          expect(directories.data.size).to eq(1)
        end
      end
    end

    context 'with search option' do
      it 'forms the proper request to the API' do
        request_args = [
          '/directories?search=Foo',
          'Content-Type' => 'application/json'
        ]

        expected_request = Net::HTTP::Get.new(*request_args)

        expect(Net::HTTP::Get).to receive(:new).with(*request_args).
          and_return(expected_request)

        VCR.use_cassette 'directory_sync/list_directories/with_search' do
          directories = described_class.list_directories(
            search: 'Foo',
          )

          expect(directories.data.size).to eq(1)
        end
      end
    end

    context 'with the before option' do
      it 'forms the proper request to the API' do
        request_args = [
          '/directories?before=before-id',
          'Content-Type' => 'application/json'
        ]

        expected_request = Net::HTTP::Get.new(*request_args)

        expect(Net::HTTP::Get).to receive(:new).with(*request_args).
          and_return(expected_request)

        VCR.use_cassette 'directory_sync/list_directories/with_before' do
          directories = described_class.list_directories(
            before: 'before-id',
          )

          expect(directories.data.size).to eq(3)
        end
      end
    end

    context 'with the after option' do
      it 'forms the proper request to the API' do
        request_args = [
          '/directories?after=after-id',
          'Content-Type' => 'application/json'
        ]

        expected_request = Net::HTTP::Get.new(*request_args)

        expect(Net::HTTP::Get).to receive(:new).with(*request_args).
          and_return(expected_request)

        VCR.use_cassette 'directory_sync/list_directories/with_after' do
          directories = described_class.list_directories(after: 'after-id')

          expect(directories.data.size).to eq(3)
        end
      end
    end

    context 'with the limit option' do
      it 'forms the proper request to the API' do
        request_args = [
          '/directories?limit=2',
          'Content-Type' => 'application/json'
        ]

        expected_request = Net::HTTP::Get.new(*request_args)

        expect(Net::HTTP::Get).to receive(:new).with(*request_args).
          and_return(expected_request)

        VCR.use_cassette 'directory_sync/list_directories/with_limit' do
          directories = described_class.list_directories(limit: 2)

          expect(directories.data.size).to eq(2)
        end
      end
    end
  end

  describe '.delete_directory' do
    context 'with valid id' do
      it 'deletes a directory' do
        VCR.use_cassette('directory_sync/delete_directory') do
          response = WorkOS::DirectorySync.delete_directory(
            'directory_01F2T098SKN5PCTVSJ7CWP70N5',
          )

          expect(response).to be(true)
        end
      end
    end
  end

  describe '.list_groups' do
    context 'with no options' do
      it 'raises an error' do
        VCR.use_cassette('directory_sync/list_groups/with_no_options') do
          expect do
            WorkOS::DirectorySync.list_groups
          end.to raise_error(WorkOS::InvalidRequestError)
        end
      end
    end

    context 'with directory option' do
      it 'forms the proper request to the API' do
        request_args = [
          '/directory_groups?directory=directory_01EK2YEMVTWGX27STRDR0N3MP9',
          'Content-Type' => 'application/json'
        ]

        expected_request = Net::HTTP::Get.new(*request_args)

        expect(Net::HTTP::Get).to receive(:new).with(*request_args).
          and_return(expected_request)

        VCR.use_cassette 'directory_sync/list_groups/with_directory' do
          groups = described_class.list_groups(
            directory: 'directory_01EK2YEMVTWGX27STRDR0N3MP9',
          )

          expect(groups.data.size).to eq(10)
        end
      end
    end

    context 'with user option' do
      it 'forms the proper request to the API' do
        request_args = [
          '/directory_groups?user=directory_user_01EK2YFBC2GQGF91EHVC',
          'Content-Type' => 'application/json'
        ]

        expected_request = Net::HTTP::Get.new(*request_args)

        expect(Net::HTTP::Get).to receive(:new).with(*request_args).
          and_return(expected_request)

        VCR.use_cassette 'directory_sync/list_groups/with_user' do
          groups = described_class.list_groups(
            user: 'directory_user_01EK2YFBC2GQGF91EHVC',
          )

          expect(groups.data.size).to eq(1)
        end
      end
    end

    context 'with the before option' do
      it 'forms the proper request to the API' do
        request_args = [
          '/directory_groups?before=before-id&' \
          'directory=directory_01EK2YEMVTWGX27STRDR0N3MP9',
          'Content-Type' => 'application/json'
        ]

        expected_request = Net::HTTP::Get.new(*request_args)

        expect(Net::HTTP::Get).to receive(:new).with(*request_args).
          and_return(expected_request)

        VCR.use_cassette 'directory_sync/list_groups/with_before' do
          groups = described_class.list_groups(
            before: 'before-id',
            directory: 'directory_01EK2YEMVTWGX27STRDR0N3MP9',
          )

          expect(groups.data.size).to eq(2)
        end
      end
    end

    context 'with the after option' do
      it 'forms the proper request to the API' do
        request_args = [
          '/directory_groups?after=after-id&' \
          'directory=directory_01EK2YEMVTWGX27STRDR0N3MP9',
          'Content-Type' => 'application/json'
        ]

        expected_request = Net::HTTP::Get.new(*request_args)

        expect(Net::HTTP::Get).to receive(:new).with(*request_args).
          and_return(expected_request)

        VCR.use_cassette 'directory_sync/list_groups/with_after' do
          groups = described_class.list_groups(
            after: 'after-id',
            directory: 'directory_01EK2YEMVTWGX27STRDR0N3MP9',
          )

          expect(groups.data.size).to eq(10)
        end
      end
    end

    context 'with the limit option' do
      it 'forms the proper request to the API' do
        request_args = [
          '/directory_groups?limit=2&' \
          'directory=directory_01EK2YEMVTWGX27STRDR0N3MP9',
          'Content-Type' => 'application/json'
        ]

        expected_request = Net::HTTP::Get.new(*request_args)

        expect(Net::HTTP::Get).to receive(:new).with(*request_args).
          and_return(expected_request)

        VCR.use_cassette 'directory_sync/list_groups/with_limit' do
          groups = described_class.list_groups(
            limit: 2,
            directory: 'directory_01EK2YEMVTWGX27STRDR0N3MP9',
          )

          expect(groups.data.size).to eq(2)
        end
      end
    end
  end

  describe '.list_users' do
    context 'with no options' do
      it 'raises an error' do
        VCR.use_cassette('directory_sync/list_users/with_no_options') do
          expect do
            WorkOS::DirectorySync.list_users
          end.to raise_error(WorkOS::InvalidRequestError)
        end
      end
    end

    context 'with directory option' do
      it 'forms the proper request to the API' do
        request_args = [
          '/directory_users?directory=directory_01EK2YEMVTWGX27STRDR0N3MP9',
          'Content-Type' => 'application/json'
        ]

        expected_request = Net::HTTP::Get.new(*request_args)

        expect(Net::HTTP::Get).to receive(:new).with(*request_args).
          and_return(expected_request)

        VCR.use_cassette 'directory_sync/list_users/with_directory' do
          users = described_class.list_users(
            directory: 'directory_01EK2YEMVTWGX27STRDR0N3MP9',
          )

          expect(users.data.size).to eq(10)
        end
      end
    end

    context 'with group option' do
      it 'forms the proper request to the API' do
        request_args = [
          '/directory_users?group=foo',
          'Content-Type' => 'application/json'
        ]

        expected_request = Net::HTTP::Get.new(*request_args)

        expect(Net::HTTP::Get).to receive(:new).with(*request_args).
          and_return(expected_request)

        VCR.use_cassette 'directory_sync/list_users/with_group' do
          users = described_class.list_users(
            group: 'foo',
          )

          expect(users.data.size).to eq(1)
        end
      end
    end

    context 'with the before option' do
      it 'forms the proper request to the API' do
        request_args = [
          '/directory_users?before=before-id&'\
          'directory=directory_01EK2YEMVTWGX27STRDR0N3MP9',
          'Content-Type' => 'application/json'
        ]

        expected_request = Net::HTTP::Get.new(*request_args)

        expect(Net::HTTP::Get).to receive(:new).with(*request_args).
          and_return(expected_request)

        VCR.use_cassette 'directory_sync/list_users/with_before' do
          users = described_class.list_users(
            before: 'before-id',
            directory: 'directory_01EK2YEMVTWGX27STRDR0N3MP9',
          )

          expect(users.data.size).to eq(2)
        end
      end
    end

    context 'with the after option' do
      it 'forms the proper request to the API' do
        request_args = [
          '/directory_users?after=after-id&' \
          'directory=directory_01EK2YEMVTWGX27STRDR0N3MP9',
          'Content-Type' => 'application/json'
        ]

        expected_request = Net::HTTP::Get.new(*request_args)

        expect(Net::HTTP::Get).to receive(:new).with(*request_args).
          and_return(expected_request)

        VCR.use_cassette 'directory_sync/list_users/with_after' do
          users = described_class.list_users(
            after: 'after-id',
            directory: 'directory_01EK2YEMVTWGX27STRDR0N3MP9',
          )

          expect(users.data.size).to eq(10)
        end
      end
    end

    context 'with the limit option' do
      it 'forms the proper request to the API' do
        request_args = [
          '/directory_users?limit=2&' \
          'directory=directory_01EK2YEMVTWGX27STRDR0N3MP9',
          'Content-Type' => 'application/json'
        ]

        expected_request = Net::HTTP::Get.new(*request_args)

        expect(Net::HTTP::Get).to receive(:new).with(*request_args).
          and_return(expected_request)

        VCR.use_cassette 'directory_sync/list_users/with_limit' do
          users = described_class.list_users(
            limit: 2,
            directory: 'directory_01EK2YEMVTWGX27STRDR0N3MP9',
          )

          expect(users.data.size).to eq(2)
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
          expect do
            WorkOS::DirectorySync.get_group('invalid')
          end.to raise_error(WorkOS::APIError)
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
          expect do
            WorkOS::DirectorySync.get_user('invalid')
          end.to raise_error(WorkOS::APIError)
        end
      end
    end
  end
end
