# frozen_string_literal: true

require "test_helper"

class TestDirectoryUser < WorkOS::TestCase
  # rubocop:disable Layout/LineLength
  def test_primary_email_with_one_primary_email
    user = WorkOS::DirectoryUser.new('{"object":"directory_user","id":"directory_user_01FAZYNPC8M0HRYTKFP2GNX852","directory_id":"directory_01FAZYMST676QMTFN1DDJZZX87","idp_id":"6092c280a3f1e19ef6d8cef8","username":"bob.fakename@workos.com","emails":[{"primary":true,"value":"bob.fakename@workos.com"}, {"primary":false,"value":"Bob@gmail.com"}],"first_name":"Bob","last_name":"Fakename","job_title":"Developer Success Engineer","state":"active","raw_attributes":{},"custom_attributes":{},"groups":[],"created_at":"2022-05-13T17:45:31.732Z", "updated_at":"2022-07-13T17:45:42.618Z"}')
    assert_equal "bob.fakename@workos.com", user.primary_email
  end

  def test_primary_email_with_multiple_primary_emails
    user = WorkOS::DirectoryUser.new('{"object":"directory_user","id":"directory_user_01FAZYNPC8M0HRYTKFP2GNX852","directory_id":"directory_01FAZYMST676QMTFN1DDJZZX87","idp_id":"6092c280a3f1e19ef6d8cef8","username":"bob.fakename@workos.com","emails":[{"primary":true,"value":"bob.fakename@workos.com"}, {"primary":true,"value":"Bob@gmail.com"}],"first_name":"Bob","last_name":"Fakename","job_title":"Developer Success Engineer","state":"active","raw_attributes":{},"custom_attributes":{},"groups":[],"created_at":"2022-05-13T17:45:31.732Z", "updated_at":"2022-07-13T17:45:42.618Z"}')
    assert_equal "bob.fakename@workos.com", user.primary_email
  end

  def test_primary_email_with_no_primary_emails
    user = WorkOS::DirectoryUser.new('{"object":"directory_user","id":"directory_user_01FAZYNPC8M0HRYTKFP2GNX852","directory_id":"directory_01FAZYMST676QMTFN1DDJZZX87","idp_id":"6092c280a3f1e19ef6d8cef8","username":"bob.fakename@workos.com","emails":[{"primary":false,"value":"Bob@gmail.com"}],"first_name":"Bob","last_name":"Fakename","job_title":"Developer Success Engineer","state":"active","raw_attributes":{},"custom_attributes":{},"groups":[],"created_at":"2022-05-13T17:45:31.732Z","updated_at":"2022-07-13T17:45:42.618Z"}')
    assert_nil user.primary_email
  end

  def test_primary_email_with_empty_email_array
    user = WorkOS::DirectoryUser.new('{"object":"directory_user","id":"directory_user_01FAZYNPC8M0HRYTKFP2GNX852","directory_id":"directory_01FAZYMST676QMTFN1DDJZZX87","idp_id":"6092c280a3f1e19ef6d8cef8","username":"bob.fakename@workos.com","emails":[],"first_name":"Bob","last_name":"Fakename","job_title":"Developer Success Engineer","state":"active","raw_attributes":{},"custom_attributes":{},"groups":[],"created_at":"2022-05-13T17:45:31.732Z","updated_at":"2022-07-13T17:45:42.618Z"}')
    assert_nil user.primary_email
  end

  def test_role_with_no_role
    user = WorkOS::DirectoryUser.new('{"object":"directory_user","id":"directory_user_01FAZYNPC8M0HRYTKFP2GNX852","directory_id":"directory_01FAZYMST676QMTFN1DDJZZX87","idp_id":"6092c280a3f1e19ef6d8cef8","username":"bob.fakename@workos.com","emails":[{"primary":true,"value":"bob.fakename@workos.com"}, {"primary":false,"value":"bob.fakename@gmail.com"}],"first_name":"Bob","last_name":"Gingerich","job_title":"Developer Success Engineer","state":"active","raw_attributes":{},"custom_attributes":{},"groups":[],"created_at":"2022-05-13T17:45:31.732Z", "updated_at":"2022-07-13T17:45:42.618Z"}')
    assert_nil user.role
    assert_nil user.roles
  end

  def test_role_with_single_role
    user = WorkOS::DirectoryUser.new('{"object":"directory_user","id":"directory_user_01FAZYNPC8M0HRYTKFP2GNX852","directory_id":"directory_01FAZYMST676QMTFN1DDJZZX87","idp_id":"6092c280a3f1e19ef6d8cef8","username":"bob.fakename@workos.com","emails":[{"primary":true,"value":"bob.fakename@workos.com"}, {"primary":false,"value":"bob.fakename@gmail.com"}],"first_name":"Bob","last_name":"Gingerich","job_title":"Developer Success Engineer","state":"active","raw_attributes":{},"custom_attributes":{},"groups":[],"role":{"slug":"member"},"roles":[{"slug":"member"}],"created_at":"2022-05-13T17:45:31.732Z", "updated_at":"2022-07-13T17:45:42.618Z"}')
    assert_equal({slug: "member"}, user.role)
    assert_equal [{slug: "member"}], user.roles
  end

  def test_role_with_multiple_roles
    user = WorkOS::DirectoryUser.new('{"object":"directory_user","id":"directory_user_01FAZYNPC8M0HRYTKFP2GNX852","directory_id":"directory_01FAZYMST676QMTFN1DDJZZX87","idp_id":"6092c280a3f1e19ef6d8cef8","username":"bob.fakename@workos.com","emails":[{"primary":true,"value":"bob.fakename@workos.com"}, {"primary":false,"value":"bob.fakename@gmail.com"}],"first_name":"Bob","last_name":"Gingerich","job_title":"Developer Success Engineer","state":"active","raw_attributes":{},"custom_attributes":{},"groups":[],"role":{"slug":"admin"},"roles":[{"slug":"member"}, {"slug":"admin"}],"created_at":"2022-05-13T17:45:31.732Z", "updated_at":"2022-07-13T17:45:42.618Z"}')
    assert_equal({slug: "admin"}, user.role)
    assert_equal [{slug: "member"}, {slug: "admin"}], user.roles
  end
  # rubocop:enable Layout/LineLength
end
