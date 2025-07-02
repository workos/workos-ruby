# frozen_string_literal: true

describe WorkOS::Role do
  describe '.initialize' do
    context 'with full role data including permissions' do
      it 'initializes all attributes correctly' do
        role_json = {
          id: 'role_01FAEAJCJ3P1Z6WP5Y9VQPN2XY',
          name: 'Admin',
          slug: 'admin',
          description: 'Administrator role with full access',
          permissions: ['read:users', 'write:users', 'admin:all'],
          type: 'system',
          created_at: '2022-05-13T17:45:31.732Z',
          updated_at: '2022-07-13T17:45:42.618Z',
        }.to_json

        role = described_class.new(role_json)

        expect(role.id).to eq('role_01FAEAJCJ3P1Z6WP5Y9VQPN2XY')
        expect(role.name).to eq('Admin')
        expect(role.slug).to eq('admin')
        expect(role.description).to eq('Administrator role with full access')
        expect(role.permissions).to eq(['read:users', 'write:users', 'admin:all'])
        expect(role.type).to eq('system')
        expect(role.created_at).to eq('2022-05-13T17:45:31.732Z')
        expect(role.updated_at).to eq('2022-07-13T17:45:42.618Z')
      end
    end

    context 'with role data without permissions' do
      it 'initializes permissions as empty array' do
        role_json = {
          id: 'role_01FAEAJCJ3P1Z6WP5Y9VQPN2XY',
          name: 'User',
          slug: 'user',
          description: 'Basic user role',
          type: 'custom',
          created_at: '2022-05-13T17:45:31.732Z',
          updated_at: '2022-07-13T17:45:42.618Z',
        }.to_json

        role = described_class.new(role_json)

        expect(role.id).to eq('role_01FAEAJCJ3P1Z6WP5Y9VQPN2XY')
        expect(role.name).to eq('User')
        expect(role.slug).to eq('user')
        expect(role.description).to eq('Basic user role')
        expect(role.permissions).to eq([])
        expect(role.type).to eq('custom')
        expect(role.created_at).to eq('2022-05-13T17:45:31.732Z')
        expect(role.updated_at).to eq('2022-07-13T17:45:42.618Z')
      end
    end

    context 'with role data with null permissions' do
      it 'initializes permissions as empty array' do
        role_json = {
          id: 'role_01FAEAJCJ3P1Z6WP5Y9VQPN2XY',
          name: 'User',
          slug: 'user',
          description: 'Basic user role',
          permissions: nil,
          type: 'custom',
          created_at: '2022-05-13T17:45:31.732Z',
          updated_at: '2022-07-13T17:45:42.618Z',
        }.to_json

        role = described_class.new(role_json)

        expect(role.permissions).to eq([])
      end
    end

    context 'with role data with empty permissions array' do
      it 'preserves empty permissions array' do
        role_json = {
          id: 'role_01FAEAJCJ3P1Z6WP5Y9VQPN2XY',
          name: 'User',
          slug: 'user',
          description: 'Basic user role',
          permissions: [],
          type: 'custom',
          created_at: '2022-05-13T17:45:31.732Z',
          updated_at: '2022-07-13T17:45:42.618Z',
        }.to_json

        role = described_class.new(role_json)

        expect(role.permissions).to eq([])
      end
    end
  end

  describe '.to_json' do
    context 'with role that has permissions' do
      it 'includes permissions in serialized output' do
        role_json = {
          id: 'role_01FAEAJCJ3P1Z6WP5Y9VQPN2XY',
          name: 'Admin',
          slug: 'admin',
          description: 'Administrator role',
          permissions: ['read:all', 'write:all'],
          type: 'system',
          created_at: '2022-05-13T17:45:31.732Z',
          updated_at: '2022-07-13T17:45:42.618Z',
        }.to_json

        role = described_class.new(role_json)
        serialized = role.to_json

        expect(serialized[:id]).to eq('role_01FAEAJCJ3P1Z6WP5Y9VQPN2XY')
        expect(serialized[:name]).to eq('Admin')
        expect(serialized[:slug]).to eq('admin')
        expect(serialized[:description]).to eq('Administrator role')
        expect(serialized[:permissions]).to eq(['read:all', 'write:all'])
        expect(serialized[:type]).to eq('system')
        expect(serialized[:created_at]).to eq('2022-05-13T17:45:31.732Z')
        expect(serialized[:updated_at]).to eq('2022-07-13T17:45:42.618Z')
      end
    end

    context 'with role that has no permissions' do
      it 'includes empty permissions array in serialized output' do
        role_json = {
          id: 'role_01FAEAJCJ3P1Z6WP5Y9VQPN2XY',
          name: 'User',
          slug: 'user',
          description: 'Basic user role',
          type: 'custom',
          created_at: '2022-05-13T17:45:31.732Z',
          updated_at: '2022-07-13T17:45:42.618Z',
        }.to_json

        role = described_class.new(role_json)
        serialized = role.to_json

        expect(serialized[:permissions]).to eq([])
      end
    end
  end
end
