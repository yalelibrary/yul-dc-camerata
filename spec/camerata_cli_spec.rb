# frozen_string_literal: true
RSpec.describe Camerata::CLI do
  subject(:cli) { described_class.new }
  before do
    app_versions = class_double('Camerata::AppVersions').as_stubbed_const(transfer_nested_constants: true)
    allow(app_versions).to receive(:load_env).and_return({})
    allow(app_versions).to receive(:get_all).and_return({})
    secrets = class_double('Camerata::Secrets').as_stubbed_const(transfer_nested_constants: true)
    allow(secrets).to receive(:load_env).and_return({})
    allow(secrets).to receive(:get_all).and_return({})
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

  context 'bin contents' do
    before do
      ENV['AWS_PROFILE'] = nil # make sure we can't actually hit aws
    end

    it 'supports method missing which matches existing shell scripts' do
      output = capture(:stdout) { cli.send('cluster-ps') }
      expect(output).to match('cluster-ps.sh')
      expect(output).to match('run')
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
end
