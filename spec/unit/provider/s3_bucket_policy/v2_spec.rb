require 'spec_helper'

describe Puppet::Type.type(:s3_bucket_policy).provider(:v2) do
  let(:resource) do
    Puppet::Type.type(:s3_bucket_policy).new(
      name: 'test-acl', bucket: 'test-bucket', region: AWS_REGION)
  end
  let(:provider) { resource.provider }
  let(:instance) { provider.class.instances.first }
  let(:s3) { provider.s3_client }

  before(:each) { stub_s3 }
  after(:each) { resource.provider.class.reset_instances! }

  describe '.prefetch' do
    it 'fetches resources' do
      Puppet::Type.type(:s3_bucket).provider(:v2).expects(:instances).returns(
        [stub('bucket', name: stub, region: AWS_REGION)])
      s3.expects(:get_bucket_policy).returns([
        stub('policy',
             id: stub,
             region: AWS_REGION,
             bucket: stub,
             version: stub,
             statement: stub)])
      provider.class.instances
      provider.class.prefetch({})
    end
  end

  describe '#exists?' do
    it 'falsy' do
      expect(provider.exists?).to be_falsy
    end

    it 'truthy' do
      Puppet::Type.type(:s3_bucket).provider(:v2).
        expects(:instances).returns([stub('bucket',
                                          region: AWS_REGION,
                                          name: stub)])
      s3.expects(:get_bucket_policy).returns([
        stub('policy',
             region: AWS_REGION,
             version: stub,
             id: stub,
             statement: stub)])
      expect(instance.exists?).to be_truthy
    end
  end

  describe '#create' do
    it 'sends request to create bucket' do
      s3.expects(:put_bucket_policy).returns(true)
      provider.expects(:instances).returns([])
      expect(provider.create).to be_truthy
    end
  end

  describe '#destroy' do
    it 'sends request to destroy bucket' do
      s3.expects(:delete_bucket_policy).returns(true)
      provider.expects(:instances).returns([])
      expect(provider.destroy).to be_truthy
    end
  end
end
