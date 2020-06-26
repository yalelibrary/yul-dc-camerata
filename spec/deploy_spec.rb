# frozen_string_literal: true
require 'spec_helper'

# Checks for Blacklight http basic auth credentials in ENV
# Sets to 'test' if none are found
username = ENV['HTTP_USERNAME'] || 'test'
password = ENV['HTTP_PASSWORD'] || 'test'

# Checks for cluster urls in ENV
# Sets to local development defaults if none are found
blacklight_url = ENV['BLACKLIGHT_URL'] || 'http://localhost:3000'
iiif_manifest_url = ENV['IIIF_MANIFEST_URL'] || 'http://localhost:8080'
iiif_image_url = ENV['IIIF_IMAGE_URL'] || 'http://localhost:8182'

RSpec.describe "The cluster at #{blacklight_url}" do
  describe "The blacklight site at #{blacklight_url}" do
    let(:uri) { "#{blacklight_url}/" }
    it 'accepts the provided HTTP_PASSWORD and HTTP_USERNAME' do
      response = HTTP.basic_auth(user: username, pass: password).get(uri)
      expect(response.code).to eq(200)
    end
    it 'loads home page with a language facet present' do
      pending 'no data found'
      response = HTTP.basic_auth(user: username, pass: password).get(uri)
      expect(response.code).to eq(200)
      expect(response.body).to match(/blacklight-language_ssim/)
    end
    describe 'has search results' do
      let(:uri) { "#{blacklight_url}/?search_field=all_fields&q=" }
      it 'with at least 5 pages' do
        pending 'no data found'
        response = HTTP.basic_auth(user: username, pass: password).get(uri)
        expect(response.code).to eq(200)
        expect(response.body).to match(/aria-label="Go to page 5"/)
      end
    end
    describe 'has a public item' do
      let(:uri) { "#{blacklight_url}/catalog/16189097" }
      it 'that shows Universal Viewer' do
        pending 'record not found'
        response = HTTP.basic_auth(user: username, pass: password).get(uri)
        expect(response.code).to eq(200)
        expect(response.body).to match(/universal-viewer-iframe/)
      end
    end
    describe 'has a yale-only item' do
      let(:uri) { URI("#{blacklight_url}/catalog/16189097-yale") }
      it 'that does not show Universal Viewer' do
        pending 'record not found'
        response = HTTP.basic_auth(user: username, pass: password).get(uri)
        expect(response.code).to eq(200)
        expect(response.body).not_to match(/universal-viewer-iframe/)
      end
    end
  end

  describe "The manifest service at #{blacklight_url}" do
    let(:uri) { "#{iiif_manifest_url}/manifests/#{oid}\.json" }
    describe 'provides a manifest for item 16686591' do
      let(:oid) { '16685691' }
      it 'serves a manifest for item 16685691 with a sequence containing one canvas' do
        response = HTTP.get(uri)
        expect(response.code).to eq(200)
        expect(JSON.parse(response.body)['sequences'][0]['canvases'].length).to eq(1)
      end
    end
    describe 'provides a manifest for item 16856582' do
      let(:oid) { '16854582' }
      it 'has a sequence with nine canvases' do
        response = HTTP.get(uri)
        expect(response.code).to eq(200)
        expect(JSON.parse(response.body)['sequences'][0]['canvases'].length).to eq(9)
      end
    end
  end

  describe "The iiif service at #{iiif_image_url}" do
    let(:uri) { "#{iiif_image_url}/iiif/2/#{oid}/info.json" }
    let(:oid) { '16854589' }
    it 'serves an info.json for image 16854589 that has a width/height ratio between 0.75 and 0.8' do
      pending "needs AWS credentials"
      response = HTTP.get(uri)
      expect(response.code).to eq(200)
      parsed = JSON.parse(response.body)
      expect(parsed['width'].to_f / parsed['height'].to_f).to be_between(0.75, 0.8).inclusive
    end
  end
end
