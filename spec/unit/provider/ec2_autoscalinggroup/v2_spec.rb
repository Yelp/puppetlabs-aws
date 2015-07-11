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

  it 'should be an instance of the ProviderV2' do
    expect(provider).to be_an_instance_of Puppet::Type::Ec2_autoscalinggroup::ProviderV2
  end

  describe 'self.prefetch' do
    it 'should exist' do
      provider.class.instances
      provider.class.prefetch({})
    end
  end

  context 'with the minimum params' do
    describe 'running create' do
      it 'should send a request to the EC2 API to create the autoscaling group' do
        with(launchconfig) do
          expect(provider.exists?).to be_falsy
          expect(provider.create).to be_truthy
          expect(instance.exists?).to be_truthy
          expect(provider.destroy).to be_truthy
        end
      end
    end
  end

  def with(resource)
    exists   = resource.class.instances.find {|i| i.name==resource.name}
    exists ||= resource.create
    yield
  ensure
    resource.destroy if exists
  end
end
