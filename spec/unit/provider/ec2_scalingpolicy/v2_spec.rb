require 'spec_helper'

region = ENV['AWS_REGION']
provider_class = Puppet::Type.type(:ec2_scalingpolicy).provider(:v2)

describe provider_class do
  let(:autoscaling_group) do
    Puppet::Type.type(:ec2_autoscalinggroup).new(
      name: 'test-asg',
      max_size: 2,
      min_size: 1,
      launch_configuration: 'test-lc',
      region: region,
      availability_zones: [region + 'a']).provider
  end

  let(:launch_configuration) do
    Puppet::Type.type(:ec2_launchconfiguration).new(
      name: 'test-lc',
      image_id: 'ami-6ef9c273',
      instance_type: 't2.micro',
      security_groups: [],
      region: region
    ).provider
  end

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

  it 'should be an instance of the ProviderV2' do
    expect(provider).to be_an_instance_of Puppet::Type::Ec2_scalingpolicy::ProviderV2
  end

  describe 'self.prefetch' do
    it 'should exist' do
      provider.class.instances
      provider.class.prefetch({})
    end
  end

  context 'with the minimum params' do
    describe 'running create and destroy' do
      it 'should send a request to the EC2 API to create the policy' do
        expect(provider.exists?).to be_falsy
        with(launch_configuration) do
          with(autoscaling_group) do
            expect(provider.create).to be_truthy
            expect(instance.exists?).to be_truthy
            expect(provider.destroy).to be_truthy
          end
        end
      end
    end
  end

  def with(object,
           find=proc{|o| o.class.instances.find{|i| i.name == o.name}},
           create=proc{|o| o.create},
           destroy=proc{|o| o.destroy})
    create.call(object) unless find.call(object)
    yield
  ensure
    destroy.call(object) if find.call(object)
  end
end
