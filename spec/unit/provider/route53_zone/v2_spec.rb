require 'spec_helper'

provider_class = Puppet::Type.type(:route53_zone).provider(:v2)

describe provider_class do
  def domain; 'example.com'; end
  def expect_hosted_zone
    route53.expects(:list_hosted_zones).returns(stub(data: stub(hosted_zones: [stub(
      name: domain,
      id: stub)])))
  end

  let(:resource) { Puppet::Type.type(:route53_zone).new(name: domain)}
  let(:provider) { resource.provider }
  let(:instance) { provider.class.instances.first }
  let(:route53) { provider.route53_client }

  before(:each) { stub_route53 }

  it 'should be an instance of the ProviderV2' do
    expect(provider).to be_an_instance_of Puppet::Type::Route53_zone::ProviderV2
  end

  describe '.prefetch' do
    it 'exists' do
      expect_hosted_zone.twice
      provider.class.instances
      provider.class.prefetch({})
    end
  end

  describe '#create' do
    it 'should send a request to the EC2 API to create the zone' do
      route53.expects(:create_hosted_zone).returns(true)
      expect(provider.create).to be_truthy
    end
  end

  describe '#exists?' do
    it 'should correctly report non-existent zones' do
      expect(provider.exists?).to be_falsy
    end

    it 'should correctly find existing zones' do
      expect_hosted_zone
      expect(instance.exists?).to be_truthy
    end
  end

  describe '#destroy' do
    it 'should send a request to the EC2 API to destroy the zone' do
      expect_hosted_zone
      route53.expects(:delete_hosted_zone).returns(true)
      expect(provider.destroy).to be_truthy
    end
  end
end
