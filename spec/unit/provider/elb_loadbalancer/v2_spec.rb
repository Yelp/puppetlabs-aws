require 'spec_helper'

provider_class = Puppet::Type.type(:elb_loadbalancer).provider(:v2)

describe provider_class do

  context 'with the minimum params' do
    let(:resource) {
      Puppet::Type.type(:elb_loadbalancer).new(
        name: 'lb-1',
        instances: ['web-1'],
        listeners: [{
          'protocol' => 'HTTP',
          'load_balancer_port' => 80,
          'instance_protocol' => 'HTTP',
          'instance_port' => 80
        }],
        availability_zones: [AWS_REGION+'a'],
        region: AWS_REGION,
      )
    }

    let(:provider) { resource.provider }

    let(:instance) { provider.class.instances.first }

    it 'should be an instance of the ProviderV2' do
      expect(provider).to be_an_instance_of Puppet::Type::Elb_loadbalancer::ProviderV2
    end

    describe 'self.prefetch' do
      it 'exists' do
        provider.class.instances
        provider.class.prefetch({})
      end
    end

    describe 'create' do
      it 'should send a request to the ELB API to create the load balancer' do
        provider.class.stubs(:add_instances_to_load_balancer => true)
        expect(provider.create).to be_truthy
      end
    end

    describe 'exists?' do
      it 'should correctly report non-existent load balancers' do
        expect(provider.exists?).to be_falsy
      end

      it 'should correctly find existing load balancers' do
        expect(instance.exists?).to be_truthy
      end
    end

    describe 'destroy' do
      it 'should send a request to the ELB API to destroy the load balancer' do
        expect(provider.destroy).to be_truthy
      end
    end
  end
end
