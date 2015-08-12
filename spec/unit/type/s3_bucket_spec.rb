require 'spec_helper'

type_class = Puppet::Type.type(:s3_bucket)

describe type_class do
  let(:params) { [ :name ] }
  let(:properties) { [ :ensure, :region ] }

  it 'should have expected properties' do
    properties.each do |property|
      expect(type_class.properties.map(&:name)).to be_include(property)
    end
  end

  it 'should have expected parameters' do
    params.each do |param|
      expect(type_class.parameters).to be_include(param)
    end
  end

  it 'should require a name' do
    expect {
      type_class.new({})
    }.to raise_error(Puppet::Error, 'Title or name must be provided')
  end

  it 'should require region to not contain spaces' do
    expect {
      type_class.new({name: 'name', region: 'invalid region'})
    }.to raise_error(Puppet::Error, /region should not contain spaces/)
  end

  it 'should accept blank region' do
    expect do
      no_region = type_class.new(name: 'name', region: '')
    end.to_not raise_error
  end

  %w{ name region }.each do |property|
    it "should require #{property} to be a string" do
      expect(type_class).to require_string_for(property)
    end
  end
end
