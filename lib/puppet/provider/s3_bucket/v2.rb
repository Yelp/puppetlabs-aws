require_relative '../../../puppet_x/puppetlabs/aws.rb'

Puppet::Type.type(:s3_bucket).provide(:v2, :parent => PuppetX::Puppetlabs::Aws) do
  confine feature: :aws

  mk_resource_methods

  def self.instances
    @instances ||= begin
      Puppet.info("Fetching S3 buckets")
      s3_client.list_buckets.buckets.map do |bucket|
        location = begin
          s3_client.get_bucket_location(bucket: bucket.name).location_constraint
        rescue Aws::S3::Errors::AccessDenied
          ''
        end
        location = 'us-east-1' if location == ''

        policy = begin
          JSON.parse(s3_client(location).get_bucket_policy(
            bucket: bucket.name).policy.read)['Statement']
        rescue Aws::S3::Errors::NoSuchBucketPolicy, Aws::S3::Errors::AccessDenied
          :absent
        end

        new(name: bucket.name,
            region: location,
            policy: policy)
      end
    end
  rescue StandardError => e
    raise PuppetX::Puppetlabs::FetchingAWSDataError.new(
      default_region, self.resource_type.name.to_s, e.message)
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
    self.class.instances.include? self
  end

  def create
    Puppet.info("Creating S3 bucket #{name}")
    region = resource[:region]
    s3_client(region).create_bucket(bucket: name)
    self.policy = @resource[:policy]
    self.instances << self
    @property_hash.merge!(region: region,
                          name: name,
                          policy: policy,
                          ensure: :present)
  end

  def destroy
    Puppet.info("Deleting S3 bucket #{name}")
    s3_client(resource[:region]).delete_bucket(bucket: name)
    instances.delete self
    @property_hash[:ensure] = :absent
  end

  def policy=(value)
    return unless value

    if [value].flatten == [:absent] # lol puppet what?
      if self.policy && self.policy != :absent
        s3_client(region).delete_bucket_policy(bucket: name)
      end
      @property_hash[:policy] = :absent
    else
      policy = JSON.dump('Statement' => [value].flatten)
      s3_client(region).put_bucket_policy(bucket: name, policy: policy)
      @property_hash[:policy] = value
    end
  end
end
