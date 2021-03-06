# frozen_string_literal: true
##
# A taggable app is microservice that we know how to make a new release for
require_relative './spec_helper'

RSpec.describe Camerata::TaggableApp, type: :github_api do
  before do
    ENV['CHANGELOG_GITHUB_TOKEN'] = 'fake_token' if ENV['CI']
  end
  context "configuration" do
    it "has a list of apps it knows how to tag" do
      expect(described_class.known_apps).to eq ["blacklight", "camerata", "management", "solr", "postgres", "iiif_imageserver"]
    end

    it "has an enhancement_prefix defined" do
      expect(described_class::ENHANCEMENT_PREFIX). to eq "New Features:"
    end

    it "has an breaking_prefix defined" do
      expect(described_class::BREAKING_PREFIX). to eq "Backwards incompatible changes:"
    end

    it "has an bug_prefix defined" do
      expect(described_class::BUG_PREFIX). to eq "Fixed Bugs:"
    end

    it "has an merge_prefix defined" do
      expect(described_class::MERGE_PREFIX). to eq "Technical Enhancements:"
    end
  end

  context "configuration for a specific app" do
    let(:taggable_app) { described_class.new("blacklight") }
    it "has a github user" do
      expect(taggable_app.github_user).to eq "yalelibrary"
    end
    it "has a github project" do
      expect(taggable_app.github_project).to eq "yul-dc-blacklight"
    end
  end

  context "#release_notes" do
    let(:taggable_app) { described_class.new("solr") }
    it "generates release notes" do
      expect(taggable_app).to respond_to(:release_notes)
    end
  end

  context "#last_version_number" do
    let(:taggable_app) { described_class.new("blacklight") }
    it "gets the last_version_number" do
      VCR.use_cassette("blacklight_last_version_number", match_requests_on: [:uri], allow_playback_repeats: true) do
        expect(taggable_app.last_version_number).to eq "v1.20.0"
      end
    end
  end

  context "tagging a release" do
    before do
      allow(taggable_app).to receive(:release_notes).and_return(release_notes)
      allow(taggable_app).to receive(:last_version_number).and_return("v1.19.0")
    end
    let(:taggable_app) { described_class.new("blacklight") }
    let(:release_notes_dir) { File.join(__dir__, 'fixtures', 'release_notes') }
    let(:release_notes) { File.open("#{release_notes_dir}/#{release_notes_fixture}", &:read) }
    context "#release_needed?" do
      context "no release needed" do
        let(:taggable_app) { described_class.new("iiif_imageserver") }
        let(:release_notes_fixture) { 'no_release_needed.txt' }
        it "#release_needed? == false" do
          expect(taggable_app.release_needed?).to eq false
        end
      end
      context "major release needed" do
        let(:taggable_app) { described_class.new("iiif_imageserver") }
        let(:release_notes_fixture) { 'major_change.txt' }
        it "#release_needed? == true" do
          expect(taggable_app.release_needed?).to eq true
        end
      end
      context "feature release needed" do
        let(:taggable_app) { described_class.new("iiif_imageserver") }
        let(:release_notes_fixture) { 'feature_change.txt' }
        it "#release_needed? == true" do
          expect(taggable_app.release_needed?).to eq true
        end
      end
      context "security release needed" do
        let(:taggable_app) { described_class.new("iiif_imageserver") }
        let(:release_notes_fixture) { 'security_change.txt' }
        it "#release_needed? == true" do
          expect(taggable_app.release_needed?).to eq true
        end
      end
    end
    context "recording a new version number" do
      context "a backwards breaking change" do
        let(:release_notes_fixture) { 'major_change.txt' }
        it "increments the major version number" do
          expect(taggable_app.new_version_number).to eq "v2.0.0"
        end
      end
      context "a new feature" do
        let(:release_notes_fixture) { 'feature_change.txt' }
        it "increments the feature number" do
          expect(taggable_app.new_version_number).to eq "v1.20.0"
        end
      end
      context "no breaking changes or features" do
        let(:release_notes_fixture) { 'minor_change.txt' }
        it "increments the patch number" do
          expect(taggable_app.new_version_number).to eq "v1.19.1"
        end
      end
    end
  end

  context "#release" do
    let(:taggable_app) { described_class.new("blacklight") }
    it "has a release method that actually does the release" do
      expect(taggable_app).to respond_to(:release)
    end
  end
  # # Camerata has an additional release step, which is to increment the version number in version.rb
  # context "#increment_camerata_version" do
  #   let(:taggable_app) { described_class.new("camerata") }
  #   it "writes a temporary version file" do
  #     VCR.use_cassette("make_version_tempfile") do
  #       tempfile = taggable_app.make_version_tempfile
  #       expect(tempfile).to be_instance_of(Tempfile)
  #       tempfile.open
  #       expect(tempfile.read).to match(taggable_app.new_version_number.delete('v'))
  #       tempfile.close
  #     end
  #   end
  # end
end
