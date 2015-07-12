require 'spec_helper'

provider_class = Puppet::Type.type(:cloudwatch_alarm).provider(:v2)

describe provider_class do

  let(:resource) {
    Puppet::Type.type(:cloudwatch_alarm).new(
      name: 'AddCapacity',
      metric: 'CPUUtilization',
      namespace: 'AWS/EC2',
      statistic: 'Average',
      period: 120,
      threshold: 60,
      comparison_operator: 'GreaterThanOrEqualToThreshold',
      evaluation_periods: 2,
      region: AWS_REGION,
    )
  }
  let(:provider) { resource.provider }
  let(:instance) { provider.class.instances.first }
  let(:client) { provider.cloudwatch_client }

  before(:each) { stub_cloudwatch }

  it 'should be an instance of the ProviderV2' do
    expect(provider).to be_an_instance_of Puppet::Type::Cloudwatch_alarm::ProviderV2
  end

  describe 'self.prefetch' do
    it 'should fetch resources' do
      client.expects(:describe_alarms).returns([]).twice
      provider.class.instances
      provider.class.prefetch({})
    end
  end

  context 'with the minimum params' do
    describe 'running create' do
      it 'should send a request to the Cloudwatch API to create the alarm' do
        client.expects(:put_metric_alarm).returns(true)
        expect(provider.create).to be_truthy
      end
    end

    describe 'running exists?' do
      it 'should correctly report non-existent alarms' do
        expect(provider.exists?).to be_falsy
      end

      it 'should correctly find existing alarms' do
        client.expects(:describe_alarms).
          returns([stub(data: stub(metric_alarms: [stub(
            alarm_actions: stub,
            alarm_name: stub,
            metric_name: stub,
            namespace: stub,
            statistic: stub,
            period: stub,
            threshold: stub,
            evaluation_periods: stub,
            comparison_operator: stub,
            dimensions: []
        )]))])
        stub_autoscaling.expects(:describe_policies).
          returns(stub(scaling_policies: []))
        expect(instance.exists?).to be_truthy
      end
    end

    describe 'running destroy' do
      it 'should send a request to the Cloudwatch API to destroy the alarm' do
        client.expects(:delete_alarms).returns(true)
        expect(provider.destroy).to be_truthy
      end
    end
  end
end
