# frozen_string_literal: true
RSpec.describe Camerata::CLI do
  subject(:cli) { described_class.new }
  before do
    app_versions = class_double('Camerata::AppVersions').as_stubbed_const(transfer_nested_constants: true)
    allow(app_versions).to receive(:load_env).and_return({})
    allow(app_versions).to receive(:get_all).and_return({})
    parameters = class_double('Camerata::Parameters').as_stubbed_const(transfer_nested_constants: true)
    allow(parameters).to receive(:set).and_return("")
    secrets = class_double('Camerata::Secrets').as_stubbed_const(transfer_nested_constants: true)
    allow(secrets).to receive(:load_env).and_return({})
    allow(secrets).to receive(:get_all).and_return({})
    allow(secrets).to receive(:get).and_return({ "Parameters" => [{ "Name" => "TEST_PARAM", "Type" => "String", "Value" => "TEST_VAL" }] })
    allow(described_class).to receive(:exit_on_failure?).and_return(false)
  end

  context 'version' do
    let(:output) { capture(:stdout) { cli.version } }

    it "has a version number" do
      expect(Camerata::VERSION).not_to be nil
    end

    it "has a working version command which prints the correct version" do
      expect(output).to match(Camerata::VERSION)
    end
  end

  context 'release' do
    let(:output) { capture(:stdout) { cli.release(:camerata, Camerata::VERSION) } }
    xit "allows releasing Camerata" do
      expect(output).not_to match("Did not find matching version string for camerata")
    end
  end

  context 'bin contents' do
    before do
      ENV['AWS_PROFILE'] = nil # make sure we can't actually hit aws
    end

    it 'supports method missing which matches existing shell scripts' do
      output = capture(:stdout) { cli.send('cluster-ps') }
      expect(output).to match('cluster-ps.sh')
      expect(output).to match('run')
    end

    it 'can run the stop-db script' do
      output = capture(:stdout) { cli.send('stop-db', 'nowhere') }
      expect(output).to match('stop-db.sh')
    end

    it 'forgives the user for putting .sh on the command' do
      output = capture(:stdout) { cli.send('cluster-ps.sh') }
      expect(output).to match('cluster-ps.sh')
      expect(output).to match('run')
    end

    it 'still shows method missing message for items not in shell scripts' do
      expect { capture(:stdout) { cli.send('cluster-aa.sh') } }.to raise_error(NoMethodError)
    end
  end

  xcontext 'up' do
    let(:output) { capture(:stdout) { cli.up } }

    it 'creates a docker compose file on the fly' do
      expect(output).to match('ahaahhaha')
    end
    it 'should have all the parts needed for the application specified'
    it 'should default to blacklight (aka the whole stack)'
  end

  context 'env_get' do
    ENV['AWS_PROFILE'] = nil # make sure we can't actually hit aws
    let(:output) { capture(:stdout) { cli.env_get "TEST_PARAM" } }
    it 'gets the value of a param from the param store' do
      expect(output).to match("TEST_VAL")
    end
  end

  context 'env_set' do
    ENV['AWS_PROFILE'] = nil # make sure we can't actually hit aws
    let(:output) { capture(:stdout) { cli.env_set("TEST_PARAM", "TEST_VALUE", true) } }
    it 'sets a param in the param store' do
      expect(output).to match("")
    end
  end

  context 'env_copy' do
    ENV['AWS_PROFILE'] = nil # make sure we can't actually hit aws

    let(:output) { capture(:stdout) { cli.env_copy "TEST_TARGET_NS" } }

    it 'requires a target "namespace"' do
      expect { capture(:stdout) { cli.env_copy } }.to raise_error(ArgumentError)
    end

    it 'copies a set of params over to a new set of namespaced params' do
      expect(output).to match('Copying following parameters from source to TEST_TARGET_NS namespace:')
    end
  end
end
