require 'spec_helper'

provider_class = Puppet::Type.type(:route53_a_record).provider(:v2)

describe provider_class do
  def domain; "notsotrivialexample.com."; end
  def zone; @zone ||= Puppet::Type.type(:route53_zone).new(name: domain); end
  def expect_hosted_zone
    route53.expects(:list_hosted_zones).returns(stub(data: stub(hosted_zones: [stub(
      name: domain,
      id: stub)])))
  end

  let(:resource) { Puppet::Type.type(:route53_a_record).new(
    name: "local.#{domain}",
    zone: domain,
    ttl: 3000,
    values: ['127.0.0.1']
  )}
  let(:provider) { resource.provider }
  let(:instance) { provider.class.instances.first }
  let(:route53) { provider.route53_client }

  before(:each) { stub_route53 }
  # before(:all) { zone.provider.create }
  # after(:all) { zone.provider.destroy }

  it 'should be an instance of the ProviderV2' do
    expect(provider).to be_an_instance_of Puppet::Type::Route53_a_record::ProviderV2
  end

  describe '.prefetch' do
    it 'exists' do
      expect_hosted_zone.twice
      route53.expects(:list_resource_record_sets).returns(stub(data: stub(
        resource_record_sets: []))).twice
      provider.class.instances
      provider.class.prefetch({})
    end
  end

  describe '#create' do
    it 'should send a request to the EC2 API to create the record' do
      expect_hosted_zone
      route53.expects(:change_resource_record_sets).returns(true)
      expect(provider.create).to be_truthy
    end
  end

  describe '#exists?' do
    it 'should correctly report non-existent records' do
      expect(provider.exists?).to be_falsy
    end

    it 'should correctly find existing records' do
      expect_hosted_zone
      route53.expects(:list_resource_record_sets).returns(stub(data: stub(
        resource_record_sets: [stub('record',
          type: 'A',
          name: domain,
          resource_records: [],
          ttl: stub)])))
      expect(instance.exists?).to be_truthy
    end
  end

  describe '#destroy' do
    it 'should send a request to the EC2 API to destroy the record' do
      expect_hosted_zone
      route53.expects(:change_resource_record_sets).returns(true)
      expect(provider.destroy).to be_truthy
    end
  end

end
