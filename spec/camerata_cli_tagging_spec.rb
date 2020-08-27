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

  context 'tag a release of a microservice' do
    context 'when it is an unrecognized name' do
      let(:output) { capture(:stdout) { cli.tag('foo') } }

      xit "needs both a tag command and a microservice name" do
        puts output
        expect(output).to eq 'FOO'
      end
    end
  end
end
