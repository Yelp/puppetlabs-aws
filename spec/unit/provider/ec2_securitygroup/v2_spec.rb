require 'spec_helper'

provider_class = Puppet::Type.type(:ec2_securitygroup).provider(:v2)

describe provider_class do

  context 'with the minimum params' do
    let(:resource) {
      Puppet::Type.type(:ec2_securitygroup).new(
        name: 'test-web-sg',
        description: 'Security group for testing',
        region: AWS_REGION,
      )
    }

    let(:provider) { resource.provider }

    let(:instance) { provider.class.instances.first }

    it 'should be an instance of the ProviderV2' do
      expect(provider).to be_an_instance_of Puppet::Type::Ec2_securitygroup::ProviderV2
    end

    describe 'self.prefetch' do
      it 'exists' do
        provider.class.instances
        provider.class.prefetch({})
      end
    end

    describe 'exists?' do
      it 'should correctly report non-existent group' do
        expect(provider.exists?).to be_falsy
      end

      it 'should correctly find existing groups' do
        expect(instance.exists?).to be_truthy
      end
    end

    describe 'create' do
      it 'should send a request to the EC2 API to create the group' do
        expect(provider.create).to be_truthy
        provider.destroy
      end
    end

    describe 'destroy' do
      it 'should send a request to the EC2 API to destroy the group' do
        provider.create
        expect(provider.destroy).to be_truthy
      end
    end
  end
end
