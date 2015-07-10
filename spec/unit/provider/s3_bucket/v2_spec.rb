require 'spec_helper'

#ENV['AWS_ACCESS_KEY_ID'] = 'redacted'
#ENV['AWS_SECRET_ACCESS_KEY'] = 'redacted'
ENV['AWS_REGION'] = 'sa-east-1'

describe Puppet::Type.type(:s3_bucket).provider(:v2), vcr: true do
  let(:resource) do
    Puppet::Type.type(:s3_bucket).new(
      name: 'test-web-sg', region: 'sa-east-1')
  end
  let(:provider) { resource.provider }
  let(:instance) { provider.class.instances.first }

  describe '.prefetch' do
    it { expect(provider.class.respond_to? :prefetch).to be_truthy }
  end

  describe '#exists?' do
    it 'should correctly report non-existent buckets' do
      expect(provider.exists?).to be_falsy
    end

    it 'should correctly find existing buckets' do
      expect(instance.exists?).to be_truthy
    end
  end

  describe '#create' do
    it 'should send a request to the EC2 API to create the bucket' do
      provider.destroy if provider.ensure == :present
      expect(provider.create).to be_truthy
      provider.destroy
    end
  end

  describe '#destroy' do
    it 'should send a request to the EC2 API to destroy the bucket' do
      provider.create if provider.ensure == :absent
      expect(provider.destroy).to be_truthy
    end
  end
end
