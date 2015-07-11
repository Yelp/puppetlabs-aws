require 'spec_helper'

provider_class = Puppet::Type.type(:route53_a_record).provider(:v2)

describe provider_class do
  context 'with the minimum params' do
    def domain; "notsotrivialexample.com."; end
    def zone; @zone ||= Puppet::Type.type(:route53_zone).new(name: domain); end

    before(:all) { zone.provider.create }
    after(:all) { zone.provider.destroy }

    let(:resource) { Puppet::Type.type(:route53_a_record).new(
      name: "local.#{domain}",
      zone: domain,
      ttl: 3000,
      values: ['127.0.0.1']
    )}

    let(:provider) { resource.provider }

    let(:instance) { provider.class.instances.first }

    it 'should be an instance of the ProviderV2' do
      expect(provider).to be_an_instance_of Puppet::Type::Route53_a_record::ProviderV2
    end

    describe 'self.prefetch' do
      it 'exists' do
        provider.class.instances
        provider.class.prefetch({})
      end
    end

    describe 'create' do
      it 'should send a request to the EC2 API to create the record' do
        expect(provider.create).to be_truthy
      end
    end

    describe 'exists?' do
      it 'should correctly report non-existent records' do
        expect(provider.exists?).to be_falsy
      end

      it 'should correctly find existing records' do
        expect(instance.exists?).to be_truthy
      end
    end

    describe 'destroy' do
      it 'should send a request to the EC2 API to destroy the record' do
        expect(provider.destroy).to be_truthy
      end
    end
  end
end
