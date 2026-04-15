# frozen_string_literal: true

require "test_helper"

class TestRole < WorkOS::TestCase
  def test_initialize_with_full_role_data_including_permissions
    role_json = {
      id: "role_01FAEAJCJ3P1Z6WP5Y9VQPN2XY",
      name: "Admin",
      slug: "admin",
      description: "Administrator role with full access",
      permissions: ["read:users", "write:users", "admin:all"],
      type: "system",
      created_at: "2022-05-13T17:45:31.732Z",
      updated_at: "2022-07-13T17:45:42.618Z"
    }.to_json

    role = WorkOS::Role.new(role_json)

    assert_equal "role_01FAEAJCJ3P1Z6WP5Y9VQPN2XY", role.id
    assert_equal "Admin", role.name
    assert_equal "admin", role.slug
    assert_equal "Administrator role with full access", role.description
    assert_equal ["read:users", "write:users", "admin:all"], role.permissions
    assert_equal "system", role.type
    assert_equal "2022-05-13T17:45:31.732Z", role.created_at
    assert_equal "2022-07-13T17:45:42.618Z", role.updated_at
  end

  def test_initialize_without_permissions
    role_json = {
      id: "role_01FAEAJCJ3P1Z6WP5Y9VQPN2XY",
      name: "User",
      slug: "user",
      description: "Basic user role",
      type: "custom",
      created_at: "2022-05-13T17:45:31.732Z",
      updated_at: "2022-07-13T17:45:42.618Z"
    }.to_json

    role = WorkOS::Role.new(role_json)

    assert_equal "role_01FAEAJCJ3P1Z6WP5Y9VQPN2XY", role.id
    assert_equal "User", role.name
    assert_equal "user", role.slug
    assert_equal "Basic user role", role.description
    assert_equal [], role.permissions
    assert_equal "custom", role.type
    assert_equal "2022-05-13T17:45:31.732Z", role.created_at
    assert_equal "2022-07-13T17:45:42.618Z", role.updated_at
  end

  def test_initialize_with_null_permissions
    role_json = {
      id: "role_01FAEAJCJ3P1Z6WP5Y9VQPN2XY",
      name: "User",
      slug: "user",
      description: "Basic user role",
      permissions: nil,
      type: "custom",
      created_at: "2022-05-13T17:45:31.732Z",
      updated_at: "2022-07-13T17:45:42.618Z"
    }.to_json

    role = WorkOS::Role.new(role_json)

    assert_equal [], role.permissions
  end

  def test_initialize_with_empty_permissions_array
    role_json = {
      id: "role_01FAEAJCJ3P1Z6WP5Y9VQPN2XY",
      name: "User",
      slug: "user",
      description: "Basic user role",
      permissions: [],
      type: "custom",
      created_at: "2022-05-13T17:45:31.732Z",
      updated_at: "2022-07-13T17:45:42.618Z"
    }.to_json

    role = WorkOS::Role.new(role_json)

    assert_equal [], role.permissions
  end

  def test_to_json_with_permissions
    role_json = {
      id: "role_01FAEAJCJ3P1Z6WP5Y9VQPN2XY",
      name: "Admin",
      slug: "admin",
      description: "Administrator role",
      permissions: ["read:all", "write:all"],
      type: "system",
      created_at: "2022-05-13T17:45:31.732Z",
      updated_at: "2022-07-13T17:45:42.618Z"
    }.to_json

    role = WorkOS::Role.new(role_json)
    serialized = role.to_json

    assert_equal "role_01FAEAJCJ3P1Z6WP5Y9VQPN2XY", serialized[:id]
    assert_equal "Admin", serialized[:name]
    assert_equal "admin", serialized[:slug]
    assert_equal "Administrator role", serialized[:description]
    assert_equal ["read:all", "write:all"], serialized[:permissions]
    assert_equal "system", serialized[:type]
    assert_equal "2022-05-13T17:45:31.732Z", serialized[:created_at]
    assert_equal "2022-07-13T17:45:42.618Z", serialized[:updated_at]
  end

  def test_to_json_without_permissions
    role_json = {
      id: "role_01FAEAJCJ3P1Z6WP5Y9VQPN2XY",
      name: "User",
      slug: "user",
      description: "Basic user role",
      type: "custom",
      created_at: "2022-05-13T17:45:31.732Z",
      updated_at: "2022-07-13T17:45:42.618Z"
    }.to_json

    role = WorkOS::Role.new(role_json)
    serialized = role.to_json

    assert_equal [], serialized[:permissions]
  end
end
