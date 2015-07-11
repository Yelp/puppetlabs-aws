require 'spec_helper'

provider_class = Puppet::Type.type(:ec2_elastic_ip).provider(:v2)

describe provider_class do

  context 'with the minimum params' do
    let(:resource) { Puppet::Type.type(:ec2_elastic_ip).new(
      name: '177.71.189.57',
      region: AWS_REGION,
      instance: 'web-1',
    )}

    let(:provider) { resource.provider }

    let(:instance) { provider.class.instances.first }

    it 'should be an instance of the ProviderV2' do
      expect(provider).to be_an_instance_of Puppet::Type::Ec2_elastic_ip::ProviderV2
    end

    describe 'self.prefetch' do
      it 'exists' do
        provider.class.instances
        provider.class.prefetch({})
      end
    end

    describe 'create' do
      it 'should send a request to the EC2 API to create the association' do
        expect(provider.create).to be_truthy
      end
    end

    describe 'exists?' do
      it 'should correctly report non-existent Elastic IP addresses' do
        expect(provider.exists?).to be_falsy
      end

      it 'should correctly find existing Elastic IP addresses' do
        expect(instance.exists?).to be_truthy
      end
    end

    describe 'destroy' do
      it 'should send a request to the EC2 API to destroy the association' do
        expect(provider.destroy).to be_truthy
      end
    end

  end

end
