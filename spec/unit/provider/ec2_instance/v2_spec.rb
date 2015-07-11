require 'spec_helper'

provider_class = Puppet::Type.type(:ec2_instance).provider(:v2)

describe provider_class do

  let(:resource) {
    Puppet::Type.type(:ec2_instance).new(
      name: 'web-15',
      image_id: 'ami-67a60d7a',
      instance_type: 't1.micro',
      availability_zone: AWS_REGION+'a',
      region: AWS_REGION,
      security_groups: ['web-sg'],
    )
  }

  let(:provider) { resource.provider }

  let(:instance) { provider.class.instances.first }

  it 'should be an instance of the ProviderV2' do
    expect(provider).to be_an_instance_of Puppet::Type::Ec2_instance::ProviderV2
  end

  describe 'self.prefetch' do
    it 'should exist' do
      provider.class.instances
      provider.class.prefetch({})
    end
  end

  context 'with the minimum params' do

    describe 'running create' do
      it 'should send a request to the EC2 API to create the instance' do
        expect(provider.create).to be_truthy
        sleep 10
      end
    end

    describe 'running exists?' do
      it 'should correctly report non-existent instances' do
        expect(provider.exists?).to be_falsy
      end

      it 'should correctly find existing instances' do
        expect(instance.exists?).to be_truthy
      end
    end

    describe 'running stop' do
      it 'should send a request to the EC2 API to stop the instance' do
        expect(provider.stop).to be_truthy
      end
    end

    describe 'running destroy' do
      it 'should send a request to the EC2 API to destroy the instance' do
        expect(provider.destroy).to be_truthy
      end
    end

  end

end
