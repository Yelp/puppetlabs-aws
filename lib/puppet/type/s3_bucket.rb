require_relative '../../puppet_x/puppetlabs/aws'
require_relative '../../puppet_x/puppetlabs/property/tag.rb'

Puppet::Type.newtype(:s3_bucket) do
  @doc = 'Type representing an S3 bucket.'

  ensurable

  newparam(:name, namevar: true) do
    desc 'The name of the S3 bucket.'
    validate do |value|
      fail 'S3 bucket must have a name' if value == ''
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

  newproperty(:tags, :parent => PuppetX::Property::AwsTag) do
    desc 'The tags for the instance.'
  end
end
