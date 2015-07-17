require 'spec_helper'

describe Puppet::Type.type(:s3_bucket_acl).provider(:v2) do
  let(:resource) do
    Puppet::Type.type(:s3_bucket_acl).new(
      name: 'test-acl', bucket: 'test-bucket', region: AWS_REGION)
  end
  let(:provider) { resource.provider }
  let(:instance) { provider.class.instances.first }
  let(:s3) { provider.s3_client }

  before(:each) { stub_s3 }
  after(:each) { resource.provider.class.reset_instances! }

  describe '.prefetch' do
    it 'fetches resources' do
      Puppet::Type.type(:s3_bucket).provider.expects(:instances).returns(
        [stub(name: stub)])
      s3.expects(:get_bucket_acl).returns(stub(owner: {}, grants: []))
      provider.class.instances
      provider.class.prefetch({})
    end
  end

  describe '#exists?' do
    it 'falsy' do
      expect(provider.exists?).to be_falsy
    end

    it 'truthy' do
      s3.expects(:list_buckets).returns(stub(buckets: [stub(name: stub)]))
      expect(instance.exists?).to be_truthy
    end
  end

  describe '#create' do
    it 'sends request to create bucket' do
      s3.expects(:create_bucket).returns(true)
      provider.expects(:instances).returns([])
      expect(provider.create).to be_truthy
    end
  end

  describe '#destroy' do
    it 'sends request to destroy bucket' do
      s3.expects(:delete_bucket).returns(true)
      provider.expects(:instances).returns([])
      expect(provider.destroy).to be_truthy
    end
  end
end
