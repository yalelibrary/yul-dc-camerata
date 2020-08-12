# frozen_string_literal: true
RSpec.describe Camerata::Parameters do

  before do
    # Stubbing call to aws cli so this can be a unit test
    allow(Camerata::Parameters).to receive(:call_aws_ssm).and_return(File.open(File.join("spec", "fixtures", 'camerata_version.json')).read)
    # stubbing the parameters method which is ordinarily provided by a subclass
    allow(Camerata::Parameters).to receive(:parameters).and_return(%w[
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
  around (:each) do |example|
    profile = ENV['AWS_PROFILE']
    region = ENV['AWS_DEFAULT_REGION']
    ENV['AWS_PROFILE'] = 'nobody'
    ENV['AWS_DEFAULT_REGION'] = 'nowhere'
    example.run
    ENV['AWS_PROFILE'] = profile
    ENV['AWS_DEFAULT_REGION'] = region
  end

  it "gets a CAMERATA_VERSION" do
    expect(described_class.get("ANYTHING")["Parameters"].first["Name"]).to eq "CAMERATA_VERSION"
  end

  it "turns ssm params into hash" do
    expect(described_class.get_hash("ANYTHING")["CAMERATA_VERSION"]).to eq "v2.4.0"
  end

end
