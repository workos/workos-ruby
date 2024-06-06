# frozen_string_literal: true

RSpec.shared_examples 'client' do
  subject(:client) { described_class.client }

  it { is_expected.to be_kind_of(Net::HTTP) }

  it 'assigns use_ssl' do
    expect(client.use_ssl?).to be true
  end

  it 'returns new instance' do
    expect(described_class.client.object_id).to_not eq described_class.client.object_id
  end

  if RUBY_VERSION >= '2.6.0'
    it 'sets the timeouts, including the write timeout' do
      expect(described_class.client.open_timeout).to_not be_nil
      expect(described_class.client.read_timeout).to_not be_nil
      expect(described_class.client.write_timeout).to_not be_nil
    end
  else
    it 'sets the open and read timeouts, but not the write timeout' do
      expect(described_class.client.open_timeout).to_not be_nil
      expect(described_class.client.read_timeout).to_not be_nil
      expect(described_class.client.write_timeout).to be_nil
    end
  end
end
