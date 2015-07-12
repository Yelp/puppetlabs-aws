require 'aws-sdk-core'
require 'puppetlabs_spec_helper/module_spec_helper'

AWS_REGION = ENV['AWS_REGION']
AWS_IMAGE  = 'ami-60f9c27d'

if ENV['PARSER'] == 'future'
  RSpec.configure do |c|
    c.parser = 'future'
  end
end

RSpec::Matchers.define :order_tags_on_output do |expected|
  match do |actual|
    tags = {'b' => 1, 'a' => 2}
    reverse = {'a' => 2, 'b' => 1}
    srv = actual.new(:name => 'sample', :tags => tags )
    expect(srv.property(:tags).insync?(tags)).to be true
    expect(srv.property(:tags).insync?(reverse)).to be true
    expect(srv.property(:tags).should_to_s(tags).to_s).to eq(reverse.to_s)
  end
  failure_message_for_should do |actual|
    "expected that #{actual} would order tags"
  end
end

RSpec::Matchers.define :require_string_for do |property|
  match do |type_class|
    config = {name: 'name'}
    config[property] = 2
    expect {
      type_class.new(config)
    }.to raise_error(Puppet::Error, /#{property} should be a String/)
  end
  failure_message_for_should do |type_class|
    "#{type_class} should require #{property} to be a String"
  end
end

RSpec::Matchers.define :require_hash_for do |property|
  match do |type_class|
    config = {name: 'name'}
    config[property] = 2
    expect {
      type_class.new(config)
    }.to raise_error(Puppet::Error, /#{property} should be a Hash/)
  end
  failure_message_for_should do |type_class|
    "#{type_class} should require #{property} to be a Hash"
  end
end

module EC2Helpers
  CLIENTS = %w{ec2 cloudwatch s3 route53 autoscaling elb rds}

  CLIENTS.each do |client|
    define_method("stub_#{client}") do
      stub.tap do |s|
        provider.stubs(:"#{client}_client" => s)
        provider.class.stubs(:"#{client}_client" => s)
      end
    end
  end
end

RSpec.configure {|c| c.include EC2Helpers}
