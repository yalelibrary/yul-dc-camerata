# frozen_string_literal: true

require 'openssl'
require 'byebug'
require 'json'
require 'http'

username = ENV['HTTP_USERNAME']
password = ENV['HTTP_PASSWORD']
server = ENV['BLACKLIGHT_URL']

RSpec.describe "The cluster at #{server}" do
  describe "The blacklight site at #{server}" do
    let(:uri) { "#{ENV['BLACKLIGHT_URL']}/" }
    it 'accepts the provided HTTP_PASSWORD and HTTP_USERNAME' do
      response = HTTP.basic_auth(user: username, pass: password).get(uri)
      expect(response.code).to eq(200)
    end
    it 'loads home page with a language facet present' do
      response = HTTP.basic_auth(user: username, pass: password).get(uri)
      expect(response.code).to eq(200)
      expect(response.body).to match(/blacklight-language_ssim/)
    end
    describe 'has search results' do
      let(:uri) { "#{ENV['BLACKLIGHT_URL']}/?search_field=all_fields&q=" }
      it 'with at least 5 pages' do
        response = HTTP.basic_auth(user: username, pass: password).get(uri)
        expect(response.code).to eq(200)
        expect(response.body).to match(/aria-label="Go to page 5"/)
      end
    end
    describe 'has a public item' do
      let(:uri) { "#{ENV['BLACKLIGHT_URL']}/catalog/16189097" }
      it 'that shows Universal Viewer' do
        response = HTTP.basic_auth(user: username, pass: password).get(uri)
        expect(response.code).to eq(200)
        expect(response.body).to match(/universal-viewer-iframe/)
      end
    end
    describe 'has a yale-only item' do
      let(:uri) { URI("#{ENV['BLACKLIGHT_URL']}/catalog/16189097-yale") }
      it 'that does not show Universal Viewer' do
        response = HTTP.basic_auth(user: username, pass: password).get(uri)
        expect(response.code).to eq(200)
        expect(response.body).not_to match(/universal-viewer-iframe/)
      end
    end
  end

  describe "The manifest service at #{server}" do
    let(:uri) { "#{ENV['IIIF_MANIFEST_URL']}/manifests/#{oid}\.json" }
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

  describe "The iiif service at #{server}" do
    let(:uri) { "#{ENV['IIIF_IMAGE_URL']}/iiif/2/#{oid}/info.json" }
    let(:oid) { '16854589' }
    it 'serves an info.json for image 16854589 that has a width/height ratio between 0.75 and 0.8' do
      response = HTTP.get(uri)
      expect(response.code).to eq(200)
      parsed = JSON.parse(response.body)
      expect(parsed['width'].to_f / parsed['height'].to_f).to be_between(0.75, 0.8).inclusive
    end
  end
end
