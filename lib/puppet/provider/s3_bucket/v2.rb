require_relative '../../../puppet_x/puppetlabs/aws.rb'

Puppet::Type.type(:s3_bucket).provide(:v2, :parent => PuppetX::Puppetlabs::Aws) do
  confine feature: :aws

  mk_resource_methods

  def self.instances
    Puppet.info("Fetching S3 buckets")
    @instances ||= s3_client.list_buckets.buckets.map do |bucket|
      location = s3_client.get_bucket_location(bucket: bucket.name).location_constraint
      location = 'us-east-1' if location == ''

      policy = begin
        JSON.parse(
          s3_client(location).get_bucket_policy(bucket: bucket.name).policy.read)
      rescue Aws::S3::Errors::NoSuchBucketPolicy
        :absent
      end

      new(name: bucket.name, region: location, policy: policy, ensure: :present)
    end
  rescue StandardError => e
    raise PuppetX::Puppetlabs::FetchingAWSDataError.new(default_region, self.resource_type.name.to_s, e.message)
  end

  def self.reset_instances!; @instances = nil; end

  def instances
    self.class.instances
  end

  def self.prefetch(resources)
    instances.each do |instance|
      next unless resource = resources[instance.name]
      resource.provider = instance if resource[:region] == instance.region
    end
  end

  def exists?
    Puppet.info("Checking if S3 bucket #{name} exists")
    @property_hash[:ensure] == :present
  end

  def create
    Puppet.info("Creating S3 bucket #{name}")
    region = resource[:region]
    s3_client(region).create_bucket(bucket: name)
    instances << self
    @property_hash.merge! region: region, name: name, ensure: :present
  end

  def destroy
    Puppet.info("Deleting S3 bucket #{name}")
    s3_client(resource[:region]).delete_bucket(bucket: name)
    instances.delete self
    @property_hash[:ensure] = :absent
  end

  def policy=(value)
    if value.to_s == 'absent'
      s3_client(region).delete_bucket_policy(bucket: name)
      @property_hash[:policy] = :absent
    else
      s3_client(region).put_bucket_policy(bucket: name, policy: JSON.dump(value))
      @property_hash[:policy] = value
    end
  end
end
