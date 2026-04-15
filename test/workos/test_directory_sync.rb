# frozen_string_literal: true

require "test_helper"

class TestDirectorySync < WorkOS::TestCase
  def test_list_directories_with_no_options
    expected_metadata = {
      "after" => nil,
      "before" => "before-id"
    }

    VCR.use_cassette "directory_sync/list_directories/with_no_options" do
      directories = WorkOS::DirectorySync.list_directories

      assert_equal 10, directories.data.size
      assert_equal expected_metadata, directories.list_metadata
    end
  end

  def test_list_directories_with_search
    VCR.use_cassette "directory_sync/list_directories/with_search" do
      directories = WorkOS::DirectorySync.list_directories(
        search: "Testing"
      )

      assert_equal 2, directories.data.size
      assert directories.data[0].name.include?("Testing")
    end
  end

  def test_list_directories_with_before
    VCR.use_cassette "directory_sync/list_directories/with_before" do
      directories = WorkOS::DirectorySync.list_directories(
        before: "directory_01FGCPNV312FHFRCX0BYWHVSE1"
      )

      assert_equal 6, directories.data.size
    end
  end

  def test_list_directories_with_after
    VCR.use_cassette "directory_sync/list_directories/with_after" do
      directories = WorkOS::DirectorySync.list_directories(
        after: "directory_01FGCPNV312FHFRCX0BYWHVSE1"
      )

      assert_equal 4, directories.data.size
    end
  end

  def test_list_directories_with_limit
    VCR.use_cassette "directory_sync/list_directories/with_limit" do
      directories = WorkOS::DirectorySync.list_directories(limit: 2)

      assert_equal 2, directories.data.size
    end
  end

  def test_delete_directory
    VCR.use_cassette("directory_sync/delete_directory") do
      response = WorkOS::DirectorySync.delete_directory(
        "directory_01F2T098SKN5PCTVSJ7CWP70N5"
      )

      assert_equal true, response
    end
  end

  def test_get_directory_with_valid_id
    VCR.use_cassette("directory_sync/get_directory_with_valid_id") do
      directory = WorkOS::DirectorySync.get_directory(
        id: "directory_01FK17DWRHH7APAFXT5B52PV0W"
      )

      assert_equal "directory_01FK17DWRHH7APAFXT5B52PV0W", directory.id
      assert_equal "Testing Active Attribute", directory.name
      assert_equal "example.me", directory.domain
      assert_equal "azure scim v2.0", directory.type
      assert_equal "linked", directory.state
      assert_equal "org_01F6Q6TFP7RD2PF6J03ANNWDKV", directory.organization_id
    end
  end

  def test_get_directory_with_invalid_id
    VCR.use_cassette("directory_sync/get_directory_with_invalid_id") do
      err = assert_raises(WorkOS::NotFoundError) do
        WorkOS::DirectorySync.get_directory(id: "invalid")
      end
      assert_equal "Status 404, Directory not found: 'invalid'. - request ID: ", err.message
    end
  end

  def test_list_groups_with_no_options_raises_error
    VCR.use_cassette("directory_sync/list_groups/with_no_options") do
      assert_raises(WorkOS::UnprocessableEntityError) do
        WorkOS::DirectorySync.list_groups
      end
    end
  end

  def test_list_groups_with_directory
    VCR.use_cassette "directory_sync/list_groups/with_directory" do
      groups = WorkOS::DirectorySync.list_groups(
        directory: "directory_01G2Z8ADK5NPMVTWF48MVVE4HT"
      )

      assert_equal 10, groups.data.size
      assert_equal groups.data[0]["name"], groups.data[0].name
    end
  end

  def test_list_groups_with_user
    VCR.use_cassette "directory_sync/list_groups/with_user" do
      groups = WorkOS::DirectorySync.list_groups(
        user: "directory_user_01G2Z8D4FDB28ZNSRRBVCF2E0P"
      )

      assert_equal 3, groups.data.size
    end
  end

  def test_list_groups_with_before
    VCR.use_cassette "directory_sync/list_groups/with_before" do
      groups = WorkOS::DirectorySync.list_groups(
        before: "directory_group_01G2Z8D4ZR8RJ03Y1W7P9K8NMG",
        directory: "directory_01G2Z8ADK5NPMVTWF48MVVE4HT"
      )

      assert_equal 10, groups.data.size
    end
  end

  def test_list_groups_with_after
    VCR.use_cassette "directory_sync/list_groups/with_after" do
      groups = WorkOS::DirectorySync.list_groups(
        after: "directory_group_01G2Z8D4ZR8RJ03Y1W7P9K8NMG",
        directory: "directory_01G2Z8ADK5NPMVTWF48MVVE4HT"
      )

      assert_equal 9, groups.data.size
    end
  end

  def test_list_groups_with_limit
    VCR.use_cassette "directory_sync/list_groups/with_limit" do
      groups = WorkOS::DirectorySync.list_groups(
        limit: 2,
        directory: "directory_01G2Z8ADK5NPMVTWF48MVVE4HT"
      )

      assert_equal 2, groups.data.size
    end
  end

  def test_list_users_with_no_options_raises_error
    VCR.use_cassette("directory_sync/list_users/with_no_options") do
      assert_raises(WorkOS::UnprocessableEntityError) do
        WorkOS::DirectorySync.list_users
      end
    end
  end

  def test_list_users_with_directory
    VCR.use_cassette "directory_sync/list_users/with_directory" do
      users = WorkOS::DirectorySync.list_users(
        directory: "directory_01FAZYMST676QMTFN1DDJZZX87"
      )

      assert_equal 4, users.data.size
      assert_equal users.data[0]["first_name"], users.data[0].first_name
    end
  end

  def test_list_users_with_group
    VCR.use_cassette "directory_sync/list_users/with_group" do
      users = WorkOS::DirectorySync.list_users(
        group: "directory_group_01FBXGP79EJAYKW0WS9JCK1V6E"
      )

      assert_equal 1, users.data.size
    end
  end

  def test_list_users_with_before
    VCR.use_cassette "directory_sync/list_users/with_before" do
      users = WorkOS::DirectorySync.list_users(
        before: "directory_user_01FAZYNPC8TJBP7Y2ERT51MGDF",
        directory: "directory_01FAZYMST676QMTFN1DDJZZX87"
      )

      assert_equal 2, users.data.size
    end
  end

  def test_list_users_with_after
    VCR.use_cassette "directory_sync/list_users/with_after" do
      users = WorkOS::DirectorySync.list_users(
        after: "directory_user_01FAZYNPC8TJBP7Y2ERT51MGDF",
        directory: "directory_01FAZYMST676QMTFN1DDJZZX87"
      )

      assert_equal 1, users.data.size
    end
  end

  def test_list_users_with_limit
    VCR.use_cassette "directory_sync/list_users/with_limit" do
      users = WorkOS::DirectorySync.list_users(
        limit: 2,
        directory: "directory_01FAZYMST676QMTFN1DDJZZX87"
      )

      assert_equal 2, users.data.size
    end
  end

  def test_get_group_with_valid_id
    VCR.use_cassette("directory_sync/get_group") do
      group = WorkOS::DirectorySync.get_group(
        "directory_group_01G2Z8D4ZR8RJ03Y1W7P9K8NMG"
      )

      assert_equal "directory_01G2Z8ADK5NPMVTWF48MVVE4HT", group["directory_id"]
      assert_equal "org_01EGS4P7QR31EZ4YWD1Z1XA176", group["organization_id"]
      assert_equal "01jlao4614two3d", group["idp_id"]
      assert_equal "Sales", group["name"]
      assert_equal "Sales", group.name
      assert_equal "2022-05-13T17:45:31.732Z", group["created_at"]
      assert_equal "2022-07-13T17:45:42.618Z", group["updated_at"]
    end
  end

  def test_get_group_with_invalid_id
    VCR.use_cassette("directory_sync/get_group_with_invalid_id") do
      assert_raises(WorkOS::NotFoundError) do
        WorkOS::DirectorySync.get_group("invalid")
      end
    end
  end

  def test_get_user_with_valid_id
    VCR.use_cassette("directory_sync/get_user") do
      user = WorkOS::DirectorySync.get_user(
        "directory_user_01FAZYNPC8M0HRYTKFP2GNX852"
      )

      assert_equal "Bob", user["first_name"]
      assert_equal "directory_01FAZYMST676QMTFN1DDJZZX87", user.directory_id
      assert_equal "org_01FAZWCWR03DVWA83NCJYKKD54", user.organization_id
      assert_equal "Bob", user.first_name
    end
  end

  def test_get_user_with_invalid_id
    VCR.use_cassette("directory_sync/get_user_with_invalid_id") do
      assert_raises(WorkOS::NotFoundError) do
        WorkOS::DirectorySync.get_user("invalid")
      end
    end
  end
end
