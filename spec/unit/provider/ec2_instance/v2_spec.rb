require 'spec_helper'

provider_class = Puppet::Type.type(:ec2_instance).provider(:v2)

describe provider_class do
  let(:resource) {
    Puppet::Type.type(:ec2_instance).new(
      name: 'test-instance',
      image_id: AWS_IMAGE,
      instance_type: 't2.micro',
      availability_zone: AWS_REGION+'a',
      region: AWS_REGION,
    )
  }

  let(:provider) { resource.provider }
  let(:instance) { provider.class.instances.first }
  let(:client) { provider.ec2_client }

  before(:each) { stub_ec2 }

  it 'should be an instance of the ProviderV2' do
    expect(provider).to be_an_instance_of Puppet::Type::Ec2_instance::ProviderV2
  end

  describe 'self.prefetch' do
    it 'should exist' do
      client.expects(:describe_subnets).returns(
        stub(data: stub(subnets: []))).twice
      client.expects(:describe_instances).returns(
        [stub(data: stub(reservations: [stub(instances: [])]))]
      ).twice
      provider.class.instances
      provider.class.prefetch({})
    end
  end

  describe '#exists?' do
    it 'falsy' do
      expect(provider.exists?).to be_falsy
    end

    it 'truthy if running' do
      provider.class.expects(:instances).returns([resource.provider])
      resource.provider.expects(:running?).returns(true)
      expect(instance.exists?).to be_truthy
    end

    it 'truthy if stopped' do
      provider.class.expects(:instances).returns([resource.provider])
      resource.provider.expects(:running?).returns(false)
      resource.provider.expects(:stopped?).returns(true)
      expect(instance.exists?).to be_truthy
    end
  end

  describe '#destroy' do
    it 'sends delete request' do
      client.expects(:terminate_instances).returns(true)
      client.expects(:wait_until).returns(true)
      expect(provider.destroy).to be_truthy
    end
  end

  describe '#stop' do
    it 'create if instance does not exists' do
      provider.expects(:exists?).returns(false)
      provider.expects(:create).returns(true)
      client.expects(:wait_until).returns(true)
      client.expects(:stop_instances).returns(true)
      expect(provider.stop).to be_truthy
    end

    it 'sends stop request' do
      provider.expects(:exists?).returns(true)
      client.expects(:wait_until).returns(true)
      client.expects(:stop_instances).returns(true)
      expect(provider.stop).to be_truthy
    end
  end

  def expect_security_group
    client.expects(:describe_security_groups).returns(
      [stub(security_groups: [stub(vpc_id: 'vpc-123',
                                   group_id: 'sg-234',
                                   group_name: 'test-group')])]
    )
  end

  describe '#create' do
    it 'should send a request to the EC2 API to create the instance' do
      expect_security_group
      client.expects(:run_instances).returns(
        stub(instances: [stub(instance_id: 'i-123')]))
      client.expects(:create_tags).returns(true)
      provider.expects(:determine_subnet).returns(
        stub(subnet_id: stub,
             vpc_id: 'vpc-123'))
      provider.expects(:using_vpc?).returns(true)
      expect(provider.create).to be_truthy
    end
  end
end
