require_relative '../../../puppet_x/puppetlabs/aws.rb'

Puppet::Type.type(:s3_bucket).provide(:v2, :parent => PuppetX::Puppetlabs::Aws) do
  confine feature: :aws

  mk_resource_methods

  def self.instances
    Puppet.info("Fetching S3 buckets")
    @instances ||= regions.map do |region|
      s3_client(region).list_buckets.buckets.map do |bucket|
        new(name: bucket.name, region: region, ensure: :present)
      end
    end.flatten
  rescue StandardError => e
    raise PuppetX::Puppetlabs::FetchingAWSDataError.new(default_region, self.resource_type.name.to_s, e.message)
  end

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
    @property_hash.merge! region: region, name: name, ensure: :present
    instances << self
  end

  def destroy
    Puppet.info("Deleting S3 bucket #{name}")
    s3_client(resource[:region]).delete_bucket(bucket: name)
    @property_hash[:ensure] = :absent
    instances.delete self
  end
end
