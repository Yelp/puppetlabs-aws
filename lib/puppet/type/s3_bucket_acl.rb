require_relative '../../puppet_x/puppetlabs/aws'

Puppet::Type.newtype(:s3_bucket_acl) do
  @doc = 'Type representing an S3 bucket ACL.'

  ensurable

  newparam(:name, namevar: true) do
    desc 'The name of ACL.'
    validate do |value|
      fail 'ACL must have a name' if value == ''
      fail 'name should be a String' unless value.is_a?(String)
    end
  end

  newproperty(:region) do
    desc 'The region in which to work with S3 buckets.'
    validate do |value|
      fail 'region should not contain spaces' if value =~ /\s/
      fail 'region should not be blank' if value == ''
      fail 'region should be a String' unless value.is_a?(String)
    end
  end

  newparam(:bucket) do
    desc 'The bucket ACL belongs to'
    validate do |value|
      fail 'bucket should be a string' unless value.is_a? String
      fail 'bucket should not be blank' if value == ''
    end
  end
end
