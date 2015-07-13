require 'spec_helper'

provider_class = Puppet::Type.type(:elb_loadbalancer).provider(:v2)

describe provider_class do
  let(:resource) do
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
      region: AWS_REGION )
  end
  let(:provider) { resource.provider }
  let(:instance) { provider.class.instances.first }
  let(:elb) { provider.elb_client }
  let(:ec2) { provider.ec2_client }

  before(:each) { stub_elb; stub_ec2 }

  it 'should be an instance of the ProviderV2' do
    expect(provider).to be_an_instance_of Puppet::Type::Elb_loadbalancer::ProviderV2
  end

  describe '.prefetch' do
    it 'exists' do
      elb.expects(:describe_load_balancers).returns([stub(data: stub(
        load_balancer_descriptions: []))]).twice
      provider.class.instances
      provider.class.prefetch({})
    end
  end

  describe '#create' do
    it 'should send a request to create the load balancer' do
      elb.expects(:create_load_balancer).returns(true)
      provider.class.stubs(:add_instances_to_load_balancer => true)
      expect(provider.create).to be_truthy
    end
  end

  describe '#exists?' do
    it 'should correctly report non-existent load balancers' do
      expect(provider.exists?).to be_falsy
    end

    it 'should correctly find existing load balancers' do
      elb.expects(:describe_load_balancers).returns([stub(data: stub(
        load_balancer_descriptions: [stub('load_balancer',
          load_balancer_name: stub,
          instances: [stub(instance_id: stub)],
          subnets: [],
          security_groups: [],
          availability_zones: [],
          scheme: stub,
          listener_descriptions: [stub(listener: stub('listener',
            protocol: stub,
            load_balancer_port: stub,
            instance_protocol: stub,
            instance_port: stub
          ))])]))])
      elb.expects(:describe_tags).returns(stub(tag_descriptions: []))
      ec2.expects(:describe_instances).returns([stub(data: stub(
        reservations: [stub(instances: [])]))])
      expect(instance.exists?).to be_truthy
    end
  end

  describe '#destroy' do
    it 'should send request to delete load balancer' do
      elb.expects(:delete_load_balancer).returns(true)
      expect(provider.destroy).to be_truthy
    end
  end
end
