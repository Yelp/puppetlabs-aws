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

  newproperty(:policy, array_matching: :all) do
    desc 'S3 bucket policy.'

    def insync?(is)
      [is].flatten == [should].flatten # LOL puppet
    end

    validate do |value|
      if value.to_s != 'absent' && !value.is_a?(Array) && !value.is_a?(Hash)
        fail 'policy must be an Array, Hash or absent'
      end
    end

    munge do |value|
      list = [value].flatten
      list.map(&:to_s) == ['absent'] ? :absent : list
    end
  end
end
