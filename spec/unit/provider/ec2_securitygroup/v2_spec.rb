require 'spec_helper'

provider_class = Puppet::Type.type(:ec2_securitygroup).provider(:v2)

describe provider_class do
  let(:resource) do
    Puppet::Type.type(:ec2_securitygroup).new(
      name: 'test-web-sg',
      description: 'Security group for testing',
      region: AWS_REGION )
  end
  let(:provider) { resource.provider }
  let(:instance) { provider.class.instances.first }
  let(:client) { provider.ec2_client }

  before(:each) { stub_ec2 }

  it 'should be an instance of the ProviderV2' do
    expect(provider).to be_an_instance_of Puppet::Type::Ec2_securitygroup::ProviderV2
  end

  describe '.prefetch' do
    it 'fetches resources' do
      client.expects(:describe_security_groups).returns(
        [stub(data: stub(security_groups: []))]).twice
      provider.class.instances
      provider.class.prefetch({})
    end
  end

  describe '#exists?' do
    it 'falsy' do
      expect(provider.exists?).to be_falsy
    end

    it 'truthy' do
      client.expects(:describe_security_groups).returns(
        [stub(data: stub(security_groups: [stub(
          vpc_id: nil,
          group_name: stub,
          group_id: stub,
          description: stub,
          tags: [],
          ip_permissions: []
        )]))]
      )
      expect(instance.exists?).to be_truthy
    end
  end

  describe '#create' do
    it 'should send a request to the EC2 API to create the group' do
      client.expects(:create_security_group).returns(
        stub(group_id: 123)
      )
      expect(provider.create).to be_truthy
    end
  end

  describe '#destroy' do
    it 'should send a request to the EC2 API to destroy the group' do
      client.expects(:delete_security_group).returns(true)
      expect(provider.destroy).to be_truthy
    end
  end
end
