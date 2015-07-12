require 'spec_helper'

provider_class = Puppet::Type.type(:ec2_launchconfiguration).provider(:v2)

describe provider_class do

  let(:resource) {
    Puppet::Type.type(:ec2_launchconfiguration).new(
      name: 'test-lc',
      image_id: AWS_IMAGE,
      instance_type: 't2.micro',
      region: AWS_REGION,
      security_groups: ['test-sg'],
    )
  }

  let(:provider) { resource.provider }

  let(:instance) { provider.class.instances.first }

  let(:client) { provider.autoscaling_client }

  before(:each) { stub_autoscaling }

  it 'should be an instance of the ProviderV2' do
    expect(provider).to be_an_instance_of Puppet::Type::Ec2_launchconfiguration::ProviderV2
  end

  describe 'self.prefetch' do
    it 'should exist' do
      client.expects(:describe_launch_configurations).returns([]).twice
      provider.class.instances
      provider.class.prefetch({})
    end
  end

  describe 'running create' do
    it 'should request to create launch configuration' do
      client.expects(:create_launch_configuration).returns(true)
      expect(provider.create).to be_truthy
    end
  end

  describe 'running exists?' do
    it 'falsy' do
      expect(provider.exists?).to be_falsy
    end

    it 'truthy' do
      client.expects(:describe_launch_configurations).returns(
        [stub(data: stub(launch_configurations: [stub(
          security_groups: [],
          launch_configuration_name: stub,
          instance_type: stub,
          image_id: stub,
          key_name: stub,
        )]))])
      stub_ec2.expects(:describe_security_groups).returns(
        stub(data: stub(security_groups: [])))
      expect(instance.exists?).to be_truthy
    end
  end

  describe 'running destroy' do
    it 'should send request to destroy launch configuration' do
      client.expects(:delete_launch_configuration).returns(true)
      expect(provider.destroy).to be_truthy
    end
  end
end
