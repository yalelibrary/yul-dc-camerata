# frozen_string_literal: true
RSpec.describe Camerata::Parameters do
  before do
    allow(Camerata::Parameters).to receive(:put_parameter).and_return("{\n    \"Version\": 1,\n    \"Tier\": \"Standard\"\n}\n")
    allow(Camerata::Parameters).to receive(:call_aws_ssm).and_return("{\n    \"Parameters\": [\n        {\n            \"Name\": \"BLACKLIGHT_VERSION\",\n            \"Type\": \"String\",\n            \"Value\": \"v1.15.1\",\n            \"Version\": 24,\n            \"LastModifiedDate\": \"2020-09-02T11:09:53.862000-07:00\",\n            \"ARN\": \"arn:aws:ssm:us-east-1:some-identifying-number:parameter/BLACKLIGHT_VERSION\",\n            \"DataType\": \"text\"\n        }\n    ],\n    \"InvalidParameters\": []\n}\n")
    allow(Camerata::Secrets).to receive(:aws_secret_access_key).and_return("a-secret-key")
    allow(Camerata::Secrets).to receive(:aws_access_key_id).and_return("an-access-key-id")
    allow(Camerata::Secrets).to receive(:aws_access_key_id).and_return("an-access-key-id")
    # Stubbing call to aws cli so this can be a unit test
    allow(described_class).to receive(:call_aws_ssm).and_return(File.open(File.join("spec", "fixtures", 'camerata_version.json')).read)
    # stubbing the parameters method which is ordinarily provided by a subclass
    allow(described_class).to receive(:parameters).and_return(%w[
                                                                BLACKLIGHT_VERSION
                                                                IIIF_IMAGE_VERSION
                                                                IIIF_MANIFEST_VERSION
                                                                MANAGEMENT_VERSION
                                                                POSTGRES_VERSION
                                                                SOLR_VERSION
                                                                CAMERATA_VERSION
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
      expect(Camerata::Parameters.create_param_name("TARGET_NS", "SOURCE_NS", "SOURCE_NS_PARAM")).to match("TARGET_NS_PARAM")
    end

    it "creates appropriate ssm param name when source ns not provided" do
      expect(Camerata::Parameters.create_param_name("TARGET_NS", "", "PARAM")).to match("TARGET_NS_PARAM")
    end
  end
end
