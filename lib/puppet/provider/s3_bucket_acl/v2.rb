require_relative '../../../puppet_x/puppetlabs/aws.rb'

Puppet::Type.type(:s3_bucket_acl).provide(:v2, :parent => PuppetX::Puppetlabs::Aws) do
  confine feature: :aws

  mk_resource_methods

  def self.instances
    Puppet.info("Fetching S3 bucket ACLs")
    @instances ||= Puppet::Type.type(:s3_bucket).provider.isntances.map do |bucket|
      acl = s3_client(region).get_bucket_acl(bucket_name: bucket.arn)
      new(bucket: bucket.name, region: region, acl: acl, ensure: :present)
    end.flatten
  rescue StandardError => e
    raise PuppetX::Puppetlabs::FetchingAWSDataError.new(default_region, self.resource_type.name.to_s, e.message)
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
    s3_client(region).put_bucket_acl(bucket_name: bucket)
    instances << self
    @property_hash.merge! region: region, name: name, ensure: :present
  end

  def destroy
    Puppet.info("Deleting S3 bucket #{name}")
    s3_client(resource[:region]).delete_bucket_acl(bucket_name: bucket)
    instances.delete self
    @property_hash[:ensure] = :absent
  end
end
