# frozen_string_literal: true
# typed: false

RSpec.shared_examples 'client' do
  subject(:client) { described_class.client }

  it { is_expected.to be_kind_of(Net::HTTP) }

  it 'assigns use_ssl' do
    expect(client.use_ssl?).to be true
  end

  it 'returns new instance' do
    expect(described_class.client.object_id).to_not eq described_class.client.object_id
  end
end
