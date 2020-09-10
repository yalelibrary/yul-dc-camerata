# frozen_string_literal: true
RSpec.describe Camerata::CLI do
  subject(:cli) { described_class.new }
  before do
    allow(Camerata::Parameters).to receive(:put_parameter).and_return("{\n    \"Version\": 1,\n    \"Tier\": \"Standard\"\n}\n")
    allow(Camerata::Parameters).to receive(:call_aws_ssm).and_return("{\n    \"Parameters\": [\n        {\n            \"Name\": \"BLACKLIGHT_VERSION\",\n            \"Value\": \"v1.15.1\"\n}]}")
    allow(Camerata::Secrets).to receive(:aws_secret_access_key).and_return("a-secret-key")
    allow(Camerata::Secrets).to receive(:aws_access_key_id).and_return("an-access-key-id")
    allow(Camerata::Secrets).to receive(:aws_access_key_id).and_return("an-access-key-id")
  end

  around do |example|
    aws_profile = ENV['AWS_PROFILE']
    aws_default_region = ENV['AWS_DEFAULT_REGION']
    ENV['AWS_PROFILE'] = 'a-user'
    ENV['AWS_DEFAULT_REGION'] = 'somestring'
    example.run
    ENV['AWS_PROFILE'] = aws_profile
    ENV['AWS_DEFAULT_REGION'] = aws_default_region
  end

  context 'env_get' do
    let(:output) { capture(:stdout) { cli.env_get "TEST_PARAM" } }
    it 'gets the value of a param from the param store' do
      expect(output).to match("v1.15.1")
    end
  end

  context 'env_set' do
    let(:output) { capture(:stdout) { cli.env_set("TEST_PARAM", "TEST_VALUE", true) } }
    it 'sets a param in the param store' do
      expect(output).to match("")
    end
  end

  context 'env_copy' do
    let(:output) { capture(:stdout) { cli.env_copy "TEST_TARGET_NS" } }

    it 'requires a target "namespace"' do
      expect { capture(:stdout) { cli.env_copy } }.to raise_error(ArgumentError)
    end

    it 'copies a set of params over to a new set of namespaced params' do
      expect(output).to match('Copying following parameters from source to TEST_TARGET_NS namespace:')
    end
  end
end
