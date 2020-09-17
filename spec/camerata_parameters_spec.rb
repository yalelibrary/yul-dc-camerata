# frozen_string_literal: true
RSpec.describe Camerata::Parameters do
  before do
    allow(described_class).to receive(:put_parameter).and_return("{\n    \"Version\": 1,\n    \"Tier\": \"Standard\"\n}\n")
    allow(described_class).to receive(:call_aws_ssm).and_return("{\n    \"Parameters\": [\n        {\n            \"Name\": \"BLACKLIGHT_VERSION\",\n            \"Value\": \"v1.15.1\"\n}]}")
    allow(Camerata::Secrets).to receive(:aws_secret_access_key).and_return("a-secret-key")
    allow(Camerata::Secrets).to receive(:aws_access_key_id).and_return("an-access-key-id")
    allow(Camerata::Secrets).to receive(:aws_access_key_id).and_return("an-access-key-id")
    # Stubbing call to aws cli so this can be a unit test
    allow(described_class).to receive(:call_aws_ssm).and_return(File.open(File.join("spec", "fixtures", 'camerata_version.json')).read)
    # stubbing the parameters method which is ordinarily provided by a subclass
    allow(described_class).to receive(:parameters).and_return(%w[
                                                                TEST_VERSION
                                                                TEST_API_KEY
                                                              ])
  end

  # moving aside the aws-related environment variables
  around do |example|
    profile = ENV['AWS_PROFILE']
    region = ENV['AWS_DEFAULT_REGION']
    ENV['AWS_PROFILE'] = 'nobody'
    ENV['AWS_DEFAULT_REGION'] = 'nowhere'
    example.run
    ENV['AWS_PROFILE'] = profile
    ENV['AWS_DEFAULT_REGION'] = region
  end

  # it "gets a CAMERATA_VERSION" do
  #   expect(described_class.get("ANYTHING")["Parameters"].first["Name"]).to eq "CAMERATA_VERSION"
  # end

  # it "turns ssm params into hash" do
  #   expect(described_class.get_hash("ANYTHING")["CAMERATA_VERSION"]).to eq "v2.4.0"
  # end

  context "create_param_name" do
    it "creates a new ssm param name" do
      expect(described_class.create_param_name("TARGET_NS", "SOURCE_NS", "/SOURCE_NS/PARAM")).to match("/TARGET_NS/PARAM")
    end

    it "creates appropriate ssm param name when source ns not provided" do
      expect(described_class.create_param_name("TARGET_NS", "", "PARAM")).to match("/TARGET_NS/PARAM")
    end
  end

  context "get_all" do
    it "gets all ssm parameters for a namespace" do
      expect(described_class.get_all("TEST_NS")).to include("/TEST_NS/TEST_API_KEY" => 2, "/TEST_NS/TEST_API_KEY" => 1)
    end
    
    # it "gets all ssm parameters from default namespace" do
    #   expect(described_class.get_all).to include("TEST_API_KEY" => 2, "TEST_API_KEY" => 1)
    # end
  end
end
