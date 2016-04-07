require_relative '../../puppet_x/puppetlabs/aws'
require_relative '../../puppet_x/puppetlabs/property/tag.rb'
require 'set'

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
      fail 'region should be a String' unless value.is_a?(String)
    end

    munge { |value| value == '' ? 'us-east-1' : value }
  end

  newproperty(:policy) do
    desc 'S3 bucket policy.'

    validate do |value|
      fail 'policy must be a Hash' unless value.is_a? Hash
    end

    # walk nested hash/array structure and convert everything
    # to sets for equality check to work
    #
    # this means order in arrays is ignored, keep that in mind
    # if copy-pasting
    def nested_to_set(obj)
      if obj.is_a? Array
        obj.map{ |v| nested_to_set(v) }.to_set
      elsif obj.is_a? Hash
        obj.inject({}) do |h,(k,v)|
          h.merge!(k => nested_to_set(v))
        end
      else
        obj
      end
    end

    def insync?(is)
      nested_to_set(is) == nested_to_set(should)
    end
  end
end
