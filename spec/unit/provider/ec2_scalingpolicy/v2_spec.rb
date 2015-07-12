require 'spec_helper'

region = ENV['AWS_REGION']
provider_class = Puppet::Type.type(:ec2_scalingpolicy).provider(:v2)

describe provider_class do
  let(:resource) do
    Puppet::Type.type(:ec2_scalingpolicy).new(
      name: 'scalein',
      auto_scaling_group: 'test-asg',
      scaling_adjustment: 30,
      adjustment_type: 'PercentChangeInCapacity',
      region: region
    )
  end
  let(:provider) { resource.provider }
  let(:instance) { provider.class.instances.first }
  let(:client) { provider.autoscaling_client }

  before(:each) { stub_autoscaling }

  it 'should be an instance of the ProviderV2' do
    expect(provider).to be_an_instance_of Puppet::Type::Ec2_scalingpolicy::ProviderV2
  end

  describe 'self.prefetch' do
    it 'should exist' do
      client.expects(:describe_policies).returns(
        [stub(data: stub(scaling_policies: []))]).twice
      provider.class.instances
      provider.class.prefetch({})
    end
  end

  describe '#exists?' do
    it 'truthy' do
      client.expects(:describe_policies).returns(
        [stub(data: stub(scaling_policies: [stub(
          policy_name: stub,
          scaling_adjustment: stub,
          adjustment_type: stub,
          auto_scaling_group_name: stub
        )]))]
      )
      expect(instance.exists?).to be_truthy
    end

    it 'falsy' do
      expect(provider.exists?).to be_falsy
    end
  end

  describe '#destroy' do
    it 'sends delete request' do
      client.expects(:delete_policy).returns(true)
      expect(provider.destroy).to be_truthy
    end
  end

  describe '#create' do
    it 'sends create request' do
      client.expects(:put_scaling_policy).returns(true)
      expect(provider.create).to be_truthy
    end
  end
end
