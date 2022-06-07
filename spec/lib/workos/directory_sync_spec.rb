# frozen_string_literal: true
# typed: false

describe WorkOS::DirectorySync do
  it_behaves_like 'client'

  describe '.list_directories' do
    context 'with no options' do
      it 'returns directories and metadata' do
        expected_metadata = {
          'after' => nil,
          'before' => 'before-id',
        }

        VCR.use_cassette 'directory_sync/list_directories/with_no_options' do
          directories = described_class.list_directories

          expect(directories.data.size).to eq(10)
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
          '/directories?search=Testing',
          'Content-Type' => 'application/json'
        ]

        expected_request = Net::HTTP::Get.new(*request_args)

        expect(Net::HTTP::Get).to receive(:new).with(*request_args).
          and_return(expected_request)

        VCR.use_cassette 'directory_sync/list_directories/with_search' do
          directories = described_class.list_directories(
            search: 'Testing',
          )

          expect(directories.data.size).to eq(2)
          expect(directories.data[0].name).to include('Testing')
        end
      end
    end

    context 'with the before option' do
      it 'forms the proper request to the API' do
        request_args = [
          '/directories?before=directory_01FGCPNV312FHFRCX0BYWHVSE1',
          'Content-Type' => 'application/json'
        ]

        expected_request = Net::HTTP::Get.new(*request_args)

        expect(Net::HTTP::Get).to receive(:new).with(*request_args).
          and_return(expected_request)

        VCR.use_cassette 'directory_sync/list_directories/with_before' do
          directories = described_class.list_directories(
            before: 'directory_01FGCPNV312FHFRCX0BYWHVSE1',
          )

          expect(directories.data.size).to eq(6)
        end
      end
    end

    context 'with the after option' do
      it 'forms the proper request to the API' do
        request_args = [
          '/directories?after=directory_01FGCPNV312FHFRCX0BYWHVSE1',
          'Content-Type' => 'application/json'
        ]

        expected_request = Net::HTTP::Get.new(*request_args)

        expect(Net::HTTP::Get).to receive(:new).with(*request_args).
          and_return(expected_request)

        VCR.use_cassette 'directory_sync/list_directories/with_after' do
          directories = described_class.list_directories(after: 'directory_01FGCPNV312FHFRCX0BYWHVSE1')

          expect(directories.data.size).to eq(4)
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

  describe '.get_directory' do
    context 'with a valid id' do
      it 'gets the directory details' do
        VCR.use_cassette('directory_sync/get_directory_with_valid_id') do
          directory = WorkOS::DirectorySync.get_directory(
            id: 'directory_01FK17DWRHH7APAFXT5B52PV0W',
          )

          expect(directory.id).to eq('directory_01FK17DWRHH7APAFXT5B52PV0W')
          expect(directory.name).to eq('Testing Active Attribute')
          expect(directory.domain).to eq('example.me')
          expect(directory.type).to eq('azure scim v2.0')
          expect(directory.state).to eq('linked')
          expect(directory.organization_id).to eq('org_01F6Q6TFP7RD2PF6J03ANNWDKV')
        end
      end
    end

    context 'with an invalid id' do
      it 'raises an error' do
        VCR.use_cassette('directory_sync/get_directory_with_invalid_id') do
          expect do
            WorkOS::DirectorySync.get_directory(id: 'invalid')
          end.to raise_error(
            WorkOS::APIError,
            "Status 404, Directory not found: 'invalid'. - request ID: ",
          )
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
          '/directory_groups?directory=directory_01G2Z8ADK5NPMVTWF48MVVE4HT',
          'Content-Type' => 'application/json'
        ]

        expected_request = Net::HTTP::Get.new(*request_args)

        expect(Net::HTTP::Get).to receive(:new).with(*request_args).
          and_return(expected_request)

        VCR.use_cassette 'directory_sync/list_groups/with_directory' do
          groups = described_class.list_groups(
            directory: 'directory_01G2Z8ADK5NPMVTWF48MVVE4HT',
          )

          expect(groups.data.size).to eq(10)
        end
      end
    end

    context 'with user option' do
      it 'forms the proper request to the API' do
        request_args = [
          '/directory_groups?user=directory_user_01G2Z8D4FDB28ZNSRRBVCF2E0P',
          'Content-Type' => 'application/json'
        ]

        expected_request = Net::HTTP::Get.new(*request_args)

        expect(Net::HTTP::Get).to receive(:new).with(*request_args).
          and_return(expected_request)

        VCR.use_cassette 'directory_sync/list_groups/with_user' do
          groups = described_class.list_groups(
            user: 'directory_user_01G2Z8D4FDB28ZNSRRBVCF2E0P',
          )

          expect(groups.data.size).to eq(3)
        end
      end
    end

    context 'with the before option' do
      it 'forms the proper request to the API' do
        request_args = [
          '/directory_groups?before=directory_group_01G2Z8D4ZR8RJ03Y1W7P9K8NMG&' \
          'directory=directory_01G2Z8ADK5NPMVTWF48MVVE4HT',
          'Content-Type' => 'application/json'
        ]

        expected_request = Net::HTTP::Get.new(*request_args)

        expect(Net::HTTP::Get).to receive(:new).with(*request_args).
          and_return(expected_request)

        VCR.use_cassette 'directory_sync/list_groups/with_before' do
          groups = described_class.list_groups(
            before: 'directory_group_01G2Z8D4ZR8RJ03Y1W7P9K8NMG',
            directory: 'directory_01G2Z8ADK5NPMVTWF48MVVE4HT',
          )

          expect(groups.data.size).to eq(10)
        end
      end
    end

    context 'with the after option' do
      it 'forms the proper request to the API' do
        request_args = [
          '/directory_groups?after=directory_group_01G2Z8D4ZR8RJ03Y1W7P9K8NMG&' \
          'directory=directory_01G2Z8ADK5NPMVTWF48MVVE4HT',
          'Content-Type' => 'application/json'
        ]

        expected_request = Net::HTTP::Get.new(*request_args)

        expect(Net::HTTP::Get).to receive(:new).with(*request_args).
          and_return(expected_request)

        VCR.use_cassette 'directory_sync/list_groups/with_after' do
          groups = described_class.list_groups(
            after: 'directory_group_01G2Z8D4ZR8RJ03Y1W7P9K8NMG',
            directory: 'directory_01G2Z8ADK5NPMVTWF48MVVE4HT',
          )

          expect(groups.data.size).to eq(9)
        end
      end
    end

    context 'with the limit option' do
      it 'forms the proper request to the API' do
        request_args = [
          '/directory_groups?limit=2&' \
          'directory=directory_01G2Z8ADK5NPMVTWF48MVVE4HT',
          'Content-Type' => 'application/json'
        ]

        expected_request = Net::HTTP::Get.new(*request_args)

        expect(Net::HTTP::Get).to receive(:new).with(*request_args).
          and_return(expected_request)

        VCR.use_cassette 'directory_sync/list_groups/with_limit' do
          groups = described_class.list_groups(
            limit: 2,
            directory: 'directory_01G2Z8ADK5NPMVTWF48MVVE4HT',
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
          '/directory_users?directory=directory_01FAZYMST676QMTFN1DDJZZX87',
          'Content-Type' => 'application/json'
        ]

        expected_request = Net::HTTP::Get.new(*request_args)

        expect(Net::HTTP::Get).to receive(:new).with(*request_args).
          and_return(expected_request)

        VCR.use_cassette 'directory_sync/list_users/with_directory' do
          users = described_class.list_users(
            directory: 'directory_01FAZYMST676QMTFN1DDJZZX87',
          )

          expect(users.data.size).to eq(4)
        end
      end
    end

    context 'with group option' do
      it 'forms the proper request to the API' do
        request_args = [
          '/directory_users?group=directory_group_01FBXGP79EJAYKW0WS9JCK1V6E',
          'Content-Type' => 'application/json'
        ]

        expected_request = Net::HTTP::Get.new(*request_args)

        expect(Net::HTTP::Get).to receive(:new).with(*request_args).
          and_return(expected_request)

        VCR.use_cassette 'directory_sync/list_users/with_group' do
          users = described_class.list_users(
            group: 'directory_group_01FBXGP79EJAYKW0WS9JCK1V6E',
          )

          expect(users.data.size).to eq(1)
        end
      end
    end

    context 'with the before option' do
      it 'forms the proper request to the API' do
        request_args = [
          '/directory_users?before=directory_user_01FAZYNPC8TJBP7Y2ERT51MGDF&'\
          'directory=directory_01FAZYMST676QMTFN1DDJZZX87',
          'Content-Type' => 'application/json'
        ]

        expected_request = Net::HTTP::Get.new(*request_args)

        expect(Net::HTTP::Get).to receive(:new).with(*request_args).
          and_return(expected_request)

        VCR.use_cassette 'directory_sync/list_users/with_before' do
          users = described_class.list_users(
            before: 'directory_user_01FAZYNPC8TJBP7Y2ERT51MGDF',
            directory: 'directory_01FAZYMST676QMTFN1DDJZZX87',
          )

          expect(users.data.size).to eq(2)
        end
      end
    end

    context 'with the after option' do
      it 'forms the proper request to the API' do
        request_args = [
          '/directory_users?after=directory_user_01FAZYNPC8TJBP7Y2ERT51MGDF&' \
          'directory=directory_01FAZYMST676QMTFN1DDJZZX87',
          'Content-Type' => 'application/json'
        ]

        expected_request = Net::HTTP::Get.new(*request_args)

        expect(Net::HTTP::Get).to receive(:new).with(*request_args).
          and_return(expected_request)

        VCR.use_cassette 'directory_sync/list_users/with_after' do
          users = described_class.list_users(
            after: 'directory_user_01FAZYNPC8TJBP7Y2ERT51MGDF',
            directory: 'directory_01FAZYMST676QMTFN1DDJZZX87',
          )

          expect(users.data.size).to eq(1)
        end
      end
    end

    context 'with the limit option' do
      it 'forms the proper request to the API' do
        request_args = [
          '/directory_users?limit=2&' \
          'directory=directory_01FAZYMST676QMTFN1DDJZZX87',
          'Content-Type' => 'application/json'
        ]

        expected_request = Net::HTTP::Get.new(*request_args)

        expect(Net::HTTP::Get).to receive(:new).with(*request_args).
          and_return(expected_request)

        VCR.use_cassette 'directory_sync/list_users/with_limit' do
          users = described_class.list_users(
            limit: 2,
            directory: 'directory_01FAZYMST676QMTFN1DDJZZX87',
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
            'directory_group_01G2Z8D4ZR8RJ03Y1W7P9K8NMG',
          )

          expect(group['directory_id']).to eq('directory_01G2Z8ADK5NPMVTWF48MVVE4HT')
          expect(group['idp_id']).to eq('01jlao4614two3d')
          expect(group['name']).to eq('Sales')
          expect(group['created_at']).to eq('2022-05-13T17:45:31.732Z')
          expect(group['updated_at']).to eq('2022-06-07T17:45:35.739Z')
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
            'directory_user_01FAZYNPC8M0HRYTKFP2GNX852',
          )

          expect(user['first_name']).to eq('Logan')
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
