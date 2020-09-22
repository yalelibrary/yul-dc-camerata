# frozen_string_literal: true
RSpec.describe Camerata::Parameters do
  before do
    allow(described_class).to receive(:put_parameter) do |arg1, arg2|
      "{\n    \"Parameters\": [\n        {\n            \"Name\": \"#{arg1}\",\n            \"Value\": \"#{arg2}\"\n}]}"
    end
    allow(Camerata::Secrets).to receive(:aws_secret_access_key).and_return("a-secret-key")
    allow(Camerata::Secrets).to receive(:aws_access_key_id).and_return("an-access-key-id")
    allow(Camerata::Secrets).to receive(:aws_access_key_id).and_return("an-access-key-id")
    # stubbing the parameters method which is ordinarily provided by a subclass
    allow(described_class).to receive(:parameters).and_return(%w[
                                                                name1
                                                                name2
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

  it "sets a parameter in the store" do
    expect(described_class.set('key1', 'value1')["Parameters"].first["Name"]).to eq('key1')
    expect(described_class.set('key1', 'value1')['Parameters'].first['Value']).to eq('value1')
  end
  it "gets a parameter from the store" do
    allow(described_class).to receive(:call_aws_ssm) do |arg|
      "{\n    \"Parameters\": [\n        {\n            \"Name\": #{arg},\n            \"Value\": #{arg}\n}]}"
    end
    expect(described_class.get(:ANYTHING)["Parameters"].first["Name"]).to eq 'ANYTHING'
  end

  context "pull_parameter_hash" do
    it "turns ssm params into hash" do
      allow(described_class).to receive(:call_aws_ssm).and_return(File.open(File.join("spec", "fixtures", 'default_params.json')).read)
      expect(described_class.pull_parameter_hash("name1 name2", "")["name2"]).to eq "default2"
    end

    it "strips the prefix off the key" do
      allow(described_class).to receive(:call_aws_ssm).with('"/TEST_NS/name1" "/TEST_NS/name2"').and_return(File.open(File.join("spec", "fixtures", "multiple_params.json")).read)
      expect(described_class.pull_parameter_hash('"/TEST_NS/name1" "/TEST_NS/name2"', "TEST_NS")["name2"]).to eq "value2"
    end

    it "tolerates an empty namespace argument" do
      allow(described_class).to receive(:call_aws_ssm).with('"name1" "name2"').and_return(File.open(File.join("spec", "fixtures", 'default_params.json')).read)
      expect(described_class.pull_parameter_hash('"name1" "name2"')["name1"]).to eq "default1"
    end
  end

  context "create_param_name" do
    it "creates a new ssm param name" do
      expect(described_class.create_param_name("TARGET_NS", "SOURCE_NS", "/SOURCE_NS/PARAM")).to match("/TARGET_NS/PARAM")
    end

    it "creates appropriate ssm param name when source ns not provided" do
      expect(described_class.create_param_name("TARGET_NS", "", "PARAM")).to match("/TARGET_NS/PARAM")
    end
  end

  context "get_all" do
    it "gets top and namespace level ssm parameters" do
      allow(described_class).to receive(:call_aws_ssm) do |arg|
        case arg
        when '"/TEST_NS/name1" "/TEST_NS/name2"'
          File.open(File.join("spec", "fixtures", 'multiple_params.json')).read
        when '"name1" "name2"'
          File.open(File.join("spec", "fixtures", 'default_params.json')).read
        end
      end
      expect(described_class.get_all("TEST_NS")).to include("name1" => "value1", "name2" => "value2", "name3" => "default3")
      expect(described_class).to have_received(:call_aws_ssm).with('"/TEST_NS/name1" "/TEST_NS/name2"')
      expect(described_class).to have_received(:call_aws_ssm).with('"name1" "name2"')
    end
    it "tolerates an empty namespace" do
      allow(described_class).to receive(:call_aws_ssm).with('"name1" "name2"').and_return(File.open(File.join("spec", "fixtures", 'default_params.json')).read)
      expect(described_class.get_all).to include("name1" => "default1", "name2" => "default2")
    end
  end
end
