require 'spec_helper'

provider_class = Puppet::Type.type(:ec2_autoscalinggroup).provider(:v2)

ENV['AWS_REGION'] = AWS_REGION

describe provider_class do
  let(:launchconfig) {
    Puppet::Type.type(:ec2_launchconfiguration).new(
      name: 'test-lc',
      image_id: AWS_IMAGE,
      instance_type: 't2.micro',
      region: AWS_REGION,
      security_groups: [],
    ).provider
  }

  let(:resource) {
    Puppet::Type.type(:ec2_autoscalinggroup).new(
      name: 'test-asg',
      max_size: 2,
      min_size: 1,
      launch_configuration: 'test-lc',
      availability_zones: [AWS_REGION+'a'],
      region: AWS_REGION,
    )
  }

  let(:provider) { resource.provider }
  let(:instance) { provider.class.instances.first }
  let(:client) { provider.autoscaling_client }

  before(:each) { stub_autoscaling }

  it 'should be an instance of the ProviderV2' do
    expect(provider).to be_an_instance_of Puppet::Type::Ec2_autoscalinggroup::ProviderV2
  end

  describe 'self.prefetch' do
    it 'should exist' do
      client.expects(:describe_auto_scaling_groups).returns([]).twice
      provider.class.instances
      provider.class.prefetch({})
    end
  end

  describe '#exists?' do
    it 'is falsy' do
      expect(provider.exists?).to be_falsy
    end

    it 'is truthy' do
      client.expects(:describe_auto_scaling_groups).
        returns([stub(data: stub(auto_scaling_groups: [stub(
          vpc_zone_identifier: nil,
          auto_scaling_group_name: stub,
          launch_configuration_name: stub,
          availability_zones: stub,
          min_size: stub,
          max_size: stub,
          instances: []
      )]))])
      expect(instance.exists?).to be_truthy
    end
  end

  describe '#destroy' do
    it 'sends destroy request' do
      client.expects(:delete_auto_scaling_group).returns(true)
      expect(provider.destroy).to be_truthy
    end
  end

  describe '#create' do
    it 'should send a request to the EC2 API to create the autoscaling group' do
      client.expects(:create_auto_scaling_group).returns(true)
      expect(provider.create).to be_truthy
    end
  end
end
