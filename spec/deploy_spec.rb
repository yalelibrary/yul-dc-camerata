# frozen_string_literal: true
require 'spec_helper'

# Checks for Blacklight http basic auth credentials in ENV
# Sets to 'test' if none are found
username = ENV['HTTP_USERNAME'] || 'test'
password = ENV['HTTP_PASSWORD'] || 'test'

# Set basic auth to .secrets settings if the .secrets file exists
if File.exist?('.secrets')
  secrets = File.read('.secrets').split

  secrets.each do |v|
    username = v.split("=")[1] if v.split("=")[0] == 'HTTP_USERNAME'
    password = v.split("=")[1] if v.split("=")[0] == 'HTTP_PASSWORD'
  end
else
  puts "No .secrets file found. Test suite is running with default basic auth credentials"
end

puts "Current Blacklight basic auth settings: " \
     "\n username: #{username}" \
     "\n password: #{password}"

# Checked for a deployed cluster host in the environment
if ENV['YUL_DC_SERVER']
  blacklight_url = "https://#{username}:#{password}@#{ENV['YUL_DC_SERVER']}"
  iiif_manifest_url = "https://#{ENV['YUL_DC_SERVER']}"
  iiif_image_url = "https://#{ENV['YUL_DC_SERVER']}"
else
  # Checks for cluster urls in ENV
  # Sets to local development defaults if none are found
  blacklight_url = ENV['BLACKLIGHT_URL'] || "http://#{username}:#{password}@localhost:3000"
  iiif_manifest_url = ENV['IIIF_MANIFEST_URL'] || 'http://localhost:80'
  iiif_image_url = ENV['IIIF_IMAGE_URL'] || 'http://localhost:8182'
end

# use this SSLContext to use https URLs without verifying certificates
# @ssl_context = OpenSSL::SSL::SSLContext.new
# @ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE
ssl_context = OpenSSL::SSL::SSLContext.new
ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE

RSpec.describe "The cluster at #{blacklight_url}", type: :feature do
  describe "The blacklight site at #{blacklight_url}" do
    let(:uri) { "#{blacklight_url}/" }
    it 'loads the home page with a language facet present' do
      visit uri
      expect(page).to have_selector(".blacklight-catalog")
      expect(page).to have_selector(".blacklight-language_ssim")
    end
    it 'is local or has a valid SSL certificate' do
      # this method is using the HTTP gem instead of capybara because
      # capybara.rb is configured to accept insecure certs to allow testing
      # deploys to ephemeral clusters
      response = HTTP.basic_auth(user: username,
                                 pass: password).get(uri)
      expect(response.code).to eq(200)
    end
    describe 'has search results' do
      let(:uri) { "#{blacklight_url}/?search_field=all_fields&q=" }
      it 'with at least 5 pages' do
        visit uri
        expect(page).to have_selector("[aria-label]", text: "5")
      end
    end
    describe 'has a public item' do
      let(:uri) { "#{blacklight_url}/catalog/16189097" }
      it 'that shows Universal Viewer' do
        visit uri
        expect(page).to have_selector(".universal-viewer-iframe")
      end
    end
    describe 'has a yale-only item' do
      let(:uri) { URI("#{blacklight_url}/catalog/16189097-yale") }
      it 'that does not show Universal Viewer' do
        visit uri
        expect(page).not_to have_selector(".universal-viewer-iframe")
      end
    end
  end

  describe "The manifest service at #{iiif_manifest_url}" do
    let(:uri) { "#{iiif_manifest_url}/manifests/#{oid}\.json" }
    describe 'provides a manifest for item 16686591' do
      let(:oid) { '16685691' }
      it 'serves a manifest for item 16685691 with a sequence containing one canvas' do
        response = HTTP.basic_auth(user: username,
                                   pass: password).get(uri, ssl_context: ssl_context)
        expect(JSON.parse(response.body)['sequences'][0]['canvases'].length).to eq(1)
      end
    end
    describe 'provides a manifest for item 16856582' do
      let(:oid) { '16854582' }
      it 'has a sequence with nine canvases' do
        response = HTTP.basic_auth(user: username,
                                   pass: password).get(uri, ssl_context: ssl_context)
        expect(JSON.parse(response.body)['sequences'][0]['canvases'].length).to eq(9)
      end
    end
  end

  describe "The iiif service at #{iiif_image_url}" do
    let(:uri) { "#{iiif_image_url}/iiif/2/#{oid}/info.json" }
    let(:oid) { '16854589' }
    it 'serves an info.json for image 16854589 that has a width/height ratio between 0.75 and 0.8' do
      response = HTTP.basic_auth(user: username,
                                 pass: password).get(uri, ssl_context: ssl_context)
      expect(response.code).to eq(200)
      parsed = JSON.parse(response.body)
      expect(parsed['width'].to_f / parsed['height'].to_f).to be_between(0.75, 0.8).inclusive
    end
  end
end
