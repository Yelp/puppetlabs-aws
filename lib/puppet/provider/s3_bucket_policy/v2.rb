require_relative '../../../puppet_x/puppetlabs/aws.rb'

Puppet::Type.type(:s3_bucket_policy).provide(:v2, :parent => PuppetX::Puppetlabs::Aws) do
  confine feature: :aws

  mk_resource_methods

  def self.instances
    Puppet.info("Fetching S3 bucket policies.")
    @instances ||= Puppet::Type.type(:s3_bucket).provider(:v2).instances.map do |bucket|
      s3_client(bucket.region).get_bucket_policy(bucket_name: bucket.name).map do |policy|
        new(name: policy.id,
            bucket: bucket.name,
            region: policy.region,
            version: policy.version,
            statement: policy.statement,
            ensure: :present)
      end
    end.flatten
  # rescue StandardError => e
  #   raise PuppetX::Puppetlabs::FetchingAWSDataError.new(
  #     default_region, self.resource_type.name.to_s, e.message)
  end

  def self.reset_instances!; @instances = nil; end
  def instances; self.class.instances; end

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
    s3_client(region).put_bucket_policy(
      id: name,
      bucket_name: bucket,
      version: version,
      statement: statement)
    instances << self
    @property_hash.merge! region: region, name: name, ensure: :present
  end

  def destroy
    Puppet.info("Deleting S3 bucket #{name}")
    s3_client(resource[:region]).delete_bucket_policy(
      id: name,
      bucket_name: bucket,
      version: version,
      statement: statement)
    instances.delete self
    @property_hash[:ensure] = :absent
  end
end
