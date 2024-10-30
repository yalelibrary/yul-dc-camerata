# frozen_string_literal: true
require_relative './smoke_helper'

# Checks for Blacklight http basic auth credentials in ENV
# Sets to 'test' if none are found
username = ENV['HTTP_USERNAME'] || 'test'
password = ENV['HTTP_PASSWORD'] || 'test'

# Set basic auth to .secrets settings if the .secrets file exists
if File.exist?('.secrets')
  secrets = File.read('.secrets').split

  secrets.each do |v|
    username = v.split('=')[1] if v.split('=')[0] == 'HTTP_USERNAME'
    password = v.split('=')[1] if v.split('=')[0] == 'HTTP_PASSWORD'
  end
end

puts 'Current Blacklight basic auth settings: ' \
     "\n username: #{username}" \
     "\n password: #{password}"

blacklight_url = case ENV['CLUSTER_NAME']
                 when 'yul-dc-prod'
                   "https://#{username}:#{password}@collections.library.yale.edu"
                 when 'yul-dc-uat'
                   "https://#{username}:#{password}@collections-uat.library.yale.edu"
                 when 'yul-dc-test'
                   "https://#{username}:#{password}@collections-test.library.yale.edu"
                 when 'yul-dc-demo'
                   "https://#{username}:#{password}@collections-demo.library.yale.edu"
                 else
                   "http://localhost:3000"
                 end

iiif_manifest_url = blacklight_url
_pdf_url = blacklight_url
iiif_image_url = blacklight_url
management_url = "#{blacklight_url}/management"

if blacklight_url.include?('3000')
  iiif_manifest_url = ENV['IIIF_MANIFEST_URL'] || 'http://localhost:80'
  _pdf_url = ENV['PDF_URL'] || 'http://localhost:80'
  iiif_image_url = ENV['IIIF_IMAGE_URL'] || 'http://localhost:8182'
  management_url = ENV['MANAGEMENT_HOST'] || 'http://localhost:3001/management'
end

# use this SSLContext to use https URLs without verifying certificates
ssl_context = OpenSSL::SSL::SSLContext.new
ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE

RSpec.describe "The cluster at #{ENV['CLUSTER_NAME']}", type: :feature do
  let(:public_parent_oid) { '2005512' }
  let(:public_child_oid) { '1030368' }
  let(:yco_parent_oid) { '2043304' }
  let(:yco_child_oid) { '1191792' }
  let(:deployed_public_parent_oid) { '16371253' }
  let(:deployed_public_child_oid) { '16394803' }
  let(:deployed_yco_parent_oid) { '2007967' }
  let(:deployed_yco_child_oid) { '1041543' }

  case ENV['CLUSTER_NAME']
  when 'yul-dc-prod'
    public_fulltext_parent_oid = '12479735'
    public_fulltext_child_oid = '14997136'
    # yco_fulltext_parent_oid = '2043304'
    # yco_fulltext_child_oid = '1191792'
  when 'yul-dc-uat'
    public_fulltext_parent_oid = '900000694'
    public_fulltext_child_oid = '900000696'
    yco_fulltext_parent_oid = '900048109'
    yco_fulltext_child_oid = '900048120'
  when 'yul-dc-test'
    public_fulltext_parent_oid = '800047436'
    public_fulltext_child_oid = '800047438'
    yco_fulltext_parent_oid = '11492783'
    yco_fulltext_child_oid = '11494521'
  when 'yul-dc-demo'
    public_fulltext_parent_oid = '2005512'
    public_fulltext_child_oid = '1030368'
    # yco_fulltext_parent_oid = '2043304'
    # yco_fulltext_child_oid = '1191792'
  else
    public_fulltext_parent_oid = '800047436'
    public_fulltext_child_oid = '800047438'
    yco_fulltext_parent_oid = '11492783'
    yco_fulltext_child_oid = '11494521'
  end
  # enable OWP tests and update ids when OWP objects are present in production
  # let(:owp_parent_oid) { '20433333304' }
  # let(:owp_child_oid) { '1191333333792' }
  # let(:deployed_owp_parent_oid) { '200788888967' }
  # let(:deployed_owp_child_oid) { '1041544533333' }
  # let(:owp_fulltext_parent_oid) { '204366666304' }
  # let(:owp_fulltext_child_oid) { '11917989889882' }

  describe "The blacklight site at #{blacklight_url}" do
    let(:uri) { "#{blacklight_url}/catalog/" }
    context 'when on campus' do
    end
    # off campus tests only work locally
    # Jenkins IP will always be on campus
    context 'when off campus', off_campus: true do
      it 'loads the home page for local environments', deployed: false do
        visit uri
        expect(page).to have_selector('.blacklight-catalog'), 'not blocked by basic auth'
        expect(page).to have_selector('.blacklight-format'), 'a format facet is present'
        expect(page).to have_selector('.branch-name', text: /Branch:\w+/)
        click_on 'search'
        expect(page).to have_selector('.document-position-1'), 'an open search has at least 1 item'
      end
      it 'loads the home page for deployed environments', deployed: true do
        visit uri
        expect(page).to have_selector('.blacklight-catalog'), 'not blocked by basic auth'
        expect(page).to have_selector('.blacklight-language_ssim'), 'a language facet is present'
        expect(page).to have_selector('.branch-name', text: /Branch:\w+/)
        click_on 'search'
        expect(page).to have_selector("[aria-label='Go to page 5']"), 'an open search has at least 5 pages'
      end
      it 'has a valid SSL certificate', deployed: true do
        # this method is using the HTTP gem instead of capybara because
        # capybara.rb is configured to accept insecure certs to allow testing
        # deploys to ephemeral clusters
        response = HTTP.basic_auth(user: username,
                                   pass: password).get(uri)
        expect(response.code).to eq(200)
      end
      describe 'has a public item' do
        it 'that shows Universal Viewer' do
          visit "#{blacklight_url}/catalog/#{public_parent_oid}"
          expect(page).to have_selector('.show-header')
          expect(page).to have_selector('.universal-viewer-iframe')
        end
      end
      describe 'has a yale-only item' do
        it 'that does not show Universal Viewer' do
          visit "#{blacklight_url}/catalog/#{yco_parent_oid}"
          expect(page).to have_selector('.show-header')
          expect(page).not_to have_selector('.universal-viewer-iframe')
        end
      end
      describe "The manifest service at #{iiif_manifest_url}" do
        describe 'can provide a manifest in any environment' do
          it 'for Public item and links to the manifest' do
            visit "#{blacklight_url}/catalog/#{public_parent_oid}"
            expect(page).to have_selector('#manifestLink')
            # Use HTTP rather than visit to avoid getting HTML on our json
            response = HTTP.basic_auth(user: username,
                                       pass: password)
                           .get(find_link('manifestLink')[:href],
                          ssl_context: ssl_context)
            expect(JSON.parse(response.body)['items'].length).to eq(2),
              'sequence contains two canvases'
          end
          it 'but not for YCO items and will not have link' do
            uri = "#{blacklight_url}/manifests/#{yco_parent_oid}\.json"
            response = HTTP.get(uri, ssl_context: ssl_context)
            # visit "#{blacklight_url}/catalog/#{yco_parent_oid}"
            # expect(page).to have_selector('#manifestLink'), visible: false
            # Use HTTP rather than visit to avoid getting HTML on our json

            # TODO: change to .get remove basic auth
            # & switch to on campus tests 

            response = HTTP.get(uri, ssl_context: ssl_context)
            expect(JSON.parse(response.body)).to eq({ 'error' => 'unauthorized' }),
              'no manifest or manifest link'
          end
          xit 'except for OWP items and will not have link' do
            uri = "#{blacklight_url}/manifests/#{owp_parent_oid}\.json"
            visit "#{blacklight_url}/catalog/#{owp_parent_oid}"
            expect(page).to have_selector('#manifestLink'), visible: false
            # Use HTTP rather than visit to avoid getting HTML on our json
            response = HTTP.basic_auth(user: username, pass: password)
                           .get(uri, ssl_context: ssl_context)
            expect(JSON.parse(response.body)).to eq({ 'error' => 'unauthorized' }),
              'no manifest or manifest link'
          end
        end
        describe 'can provide a manifest in deployed environment', deployed: true do
          it 'for Public item and links to the manifest' do
            uri = "#{iiif_manifest_url}/manifests/#{deployed_public_parent_oid}\.json"
            response = HTTP.basic_auth(user: username,
                                       pass: password).get(uri, ssl_context: ssl_context)
            parsed_manifest = JSON.parse(response.body)
            expect(parsed_manifest['items'].length).to eq(6), 'sequence contains six canvases'
            image_uri = parsed_manifest['items'][0]['items'][0]['items'][0]['body']['id']
            response = HTTP.basic_auth(user: username,
                                       pass: password)
                           .get(image_uri, ssl_context: ssl_context)
            expect(response.code).to eq 200, 'image retrievable'
          end
          it 'except for YCO items and will not have link' do
            uri = "#{iiif_manifest_url}/manifests/#{deployed_yco_parent_oid}\.json"
            expect(page).not_to have_selector('#manifestLink'), 'no manifest link'
            # Use HTTP rather than visit to avoid getting HTML on our json
            response = HTTP.basic_auth(user: username,
                                       pass: password)
                           .get(uri,
                          ssl_context: ssl_context)
            expect(JSON.parse(response.body)).to eq({ 'error' => 'unauthorized' }),
              'no manifest'
          end
          xit 'except for OWP items and will not have link' do
            uri = "#{iiif_manifest_url}/manifests/#{deployed_owp_parent_oid}\.json"
            expect(page).not_to have_selector('#manifestLink'), 'no manifest link'
            # Use HTTP rather than visit to avoid getting HTML on our json
            response = HTTP.basic_auth(user: username,
                                       pass: password)
                           .get(uri,
                          ssl_context: ssl_context)
            expect(JSON.parse(response.body)).to eq({ 'error' => 'unauthorized' }),
              'no manifest'
          end
        end
      end
      describe "The iiif service at #{iiif_image_url}" do
        describe 'info.json' do
          it 'serves an info.json for Public image that has a width/height ratio between 1.5 and 1.7' do
            uri = "#{iiif_image_url}/iiif/2/#{public_child_oid}/info.json"
            response = HTTP.basic_auth(user: username,
                                       pass: password).get(uri, ssl_context: ssl_context)
            expect(response.code).to eq(200)
            parsed = JSON.parse(response.body)
            expect(parsed['width'].to_f / parsed['height'].to_f).to be_between(1.5, 1.7).inclusive
          end
        end
        describe 'default.jpg' do
          it 'serves a jpg for Public image' do
            uri = "#{iiif_image_url}/iiif/2/#{public_child_oid}/full/!200,200/0/default.jpg"
            response = HTTP.basic_auth(user: username,
                                       pass: password).get(uri, ssl_context: ssl_context)
            expect(response.code).to eq(200)
            expect(response.mime_type).to eq 'image/jpeg'
            expect(response['Content-Disposition']).to eq("inline; filename=\"1030368.jpg\"")
          end
          it 'does not serve a jpg for YCO image' do
            uri = "#{iiif_image_url}/iiif/2/#{yco_child_oid}/full/!200,200/0/default.jpg"
            response = HTTP.basic_auth(user: username,
                                       pass: password).get(uri, ssl_context: ssl_context)
            expect(response.code).to eq(404)
            expect(response.mime_type).to eq 'text/plain'
          end
          xit 'does not serve a jpg for OWP image' do
            uri = "#{iiif_image_url}/iiif/2/#{owp_child_oid}/full/!200,200/0/default.jpg"
            response = HTTP.basic_auth(user: username,
                                       pass: password).get(uri, ssl_context: ssl_context)
            expect(response.code).to eq(404)
            expect(response.mime_type).to eq 'text/plain'
          end
        end
      end
      describe 'annotations', deployed: true do
        it 'serves an annotation for Public image' do
          uri = "#{blacklight_url}/annotation/oid/#{public_fulltext_parent_oid}/canvas/#{public_fulltext_child_oid}/fulltext?oid=#{public_fulltext_parent_oid}&child_oid=#{public_fulltext_child_oid}"
          response = HTTP.basic_auth(user: username,
                                     pass: password).get(uri, ssl_context: ssl_context)
          expect(response.code).to eq(200)
          expect(response.body).to eq 'page'
        end
        # no yco fulltext in prod or demo
        if ENV['CLUSTER_NAME'] != 'yul-dc-prod' || ENV['CLUSTER_NAME'] != 'yul-dc-demo'
          it 'does not serve an annotation for YCO image' do
            uri = "#{blacklight_url}/annotation/oid/#{yco_fulltext_parent_oid}/canvas/#{yco_fulltext_child_oid}/fulltext?oid=#{yco_fulltext_parent_oid}&child_oid=#{yco_fulltext_child_oid}"
            response = HTTP.basic_auth(user: username,
                                       pass: password).get(uri, ssl_context: ssl_context)
            expect(response.code).to eq(401), 'has unauthorized response'
            expect(JSON.parse(response.body)).to eq({ 'error' => 'unauthorized' })
          end
        end
        xit 'does not serve an annotation for OWP image' do
          uri = "#{blacklight_url}/annotation/oid/#{owp_fulltext_parent_oid}/canvas/#{owp_fulltext_child_oid}/fulltext?oid=#{owp_fulltext_parent_oid}&child_oid=#{owp_fulltext_child_oid}"
          response = HTTP.basic_auth(user: username,
                                     pass: password).get(uri, ssl_context: ssl_context)
          expect(response.code).to eq(401), 'has unauthorized response'
          expect(JSON.parse(response.body)).to eq({ 'error' => 'unauthorized' })
        end
      end
      # needs deployed because of connection to management
      describe 'tiff download', deployed: true do
        it 'for Public image' do
          action_uri = "#{blacklight_url}/download/tiff/#{public_child_oid}/staged"
          retrieval_uri = "#{blacklight_url}/download/tiff/#{public_child_oid}"
          response = HTTP.basic_auth(user: username,
                                     pass: password).get(action_uri, ssl_context: ssl_context)
          expect(response.code).to eq(200), 'has success response'
          response = HTTP.basic_auth(user: username,
                                     pass: password).get(retrieval_uri, ssl_context: ssl_context)
          expect(response.mime_type).to eq 'image/jpeg'
          expect(response['Content-Disposition']).to eq("inline; filename=\"1030368.jpg\""), 'serves a tiff'
        end
        it 'for YCO image' do
          action_uri = "#{blacklight_url}/download/tiff/#{yco_child_oid}/staged"
          retrieval_uri = "#{blacklight_url}/download/tiff/#{yco_child_oid}"
          response = HTTP.basic_auth(user: username,
                                     pass: password).get(action_uri, ssl_context: ssl_context)
          expect(response.code).to eq(401), 'has unauthorized response'
          response = HTTP.basic_auth(user: username,
                                     pass: password).get(retrieval_uri, ssl_context: ssl_context)
          expect(response.mime_type).to eq 'text/plain', 'does not serve a tiff'
        end
        xit 'for OWP image' do
          action_uri = "#{blacklight_url}/download/tiff/#{owp_child_oid}/staged"
          retrieval_uri = "#{blacklight_url}/download/tiff/#{owp_child_oid}"
          response = HTTP.basic_auth(user: username,
                                     pass: password).get(action_uri, ssl_context: ssl_context)
          expect(response.code).to eq(401), 'has unauthorized response'
          response = HTTP.basic_auth(user: username,
                                     pass: password).get(retrieval_uri, ssl_context: ssl_context)
          expect(response.mime_type).to eq 'text/plain', 'does not serve a tiff'
        end
      end
      describe 'pdfs' do
        it 'serves a pdf for Public image' do
          response = HTTP.basic_auth(user: username,
                                     pass: password).get("#{blacklight_url}/pdfs/#{public_parent_oid}.pdf", ssl_context: ssl_context)
          expect(response.code).to eq(200)
          expect(response.mime_type).to eq 'application/pdf'
        end
        it 'does not serve a pdf for YCO image' do
          response = HTTP.basic_auth(user: username,
                                     pass: password).get("#{blacklight_url}/pdfs/#{yco_parent_oid}.pdf", ssl_context: ssl_context)
          expect(response.code).to eq(401), 'has unauthorized response'
          expect(response.mime_type).to eq 'application/json'
        end
        xit 'does not serve a pdf for OWP image' do
          response = HTTP.basic_auth(user: username,
                                     pass: password).get("#{blacklight_url}/pdfs/#{owp_parent_oid}.pdf", ssl_context: ssl_context)
          expect(response.code).to eq(401), 'has unauthorized response'
          expect(response.mime_type).to eq 'application/json'
        end
      end
      describe 'owp request service' do
        let(:request_uri) { "#{blacklight_url}/catalog/#{owp_parent_oid}/request_form" }
        let(:terms_uri) { "#{blacklight_url}/catalog/#{owp_parent_oid}/terms_and_conditions" }
        let(:confirmation_uri) { "#{blacklight_url}/catalog/#{owp_parent_oid}/request_confirmation" }
        xit 'will not be accessible' do
          response = HTTP.basic_auth(user: username,
                                     pass: password).get(request_uri, ssl_context: ssl_context)
          expect(response.code).to eq(401), 'has unauthorized response'
          expect(JSON.parse(response.body)).to eq({ 'error' => 'unauthorized' }), 'request form'
          response = HTTP.basic_auth(user: username,
                                     pass: password).get(terms_uri, ssl_context: ssl_context)
          expect(response.code).to eq(401), 'has unauthorized response'
          expect(JSON.parse(response.body)).to eq({ 'error' => 'unauthorized' }), 'terms and conditions'
          response = HTTP.basic_auth(user: username,
                                     pass: password).get(confirmation_uri, ssl_context: ssl_context)
          expect(response.code).to eq(401), 'has unauthorized response'
          expect(JSON.parse(response.body)).to eq({ 'error' => 'unauthorized' }), 'request confirmation'
        end
      end
    end
  end
  describe "The management site at #{management_url}" do
    # This information is now protected behind CAS authentication.
    # Removing this test for now. We will restore it when we have a CAS account.
    xit 'has version numbers in the table' do
      visit management_url
      expect(page).to have_selector('#management_version', text: /v\d+.\d+.\d+/)
      expect(page).to have_selector('#postgres_version', text: /v\d+.\d+.\d+/)
      expect(page).to have_selector('#blacklight_version', text: /v\d+.\d+.\d+/)
      expect(page).to have_selector('#solr_version', text: /v\d+.\d+.\d+/)
      expect(page).to have_selector('#iiif_image_version', text: /v\d+.\d+.\d+/)
      expect(page).to have_selector('#iiif_manifest_version', text: /v\d+.\d+.\d+/)
      expect(page).to have_selector('#camerata_version', text: /v\d+.\d+.\d+/)
    end
    it 'prompts the user to sign in' do
      visit management_url
      expect(page).to have_button('You must sign in')
    end
    describe '/api' do
      context 'when off campus', off_campus: true do
        it 'will not restrict access to Public' do
          visit "#{management_url}/api/download/stage/child/#{public_child_oid}"
          expect(page.body.include?('staged for download')).to eq(true), '/api/download/stage/child/:child_oid'
        end
        it 'will not restrict access to YCO' do
          visit "#{management_url}/api/download/stage/child/#{yco_child_oid}"
          expect(page.body.include?('staged for download')).to eq(true), '/api/download/stage/child/:child_oid'
          # currently no user permission checks on this action - this will need updated once the permission checks are updated
          # expect(page.body.include?('error')).to eq(true), '/api/download/stage/child/:child_oid'
        end
        xit 'will restrict access to OWP' do
          visit "#{management_url}/api/download/stage/child/9999999"
          expect(page.body.include?('error')).to eq(true), '/api/download/stage/child/:child_oid'
          permission_requests_url = "#{management_url}/api/permission_requests"
          request = JSON.parse({})
          response = HTTP.post(permission_requests_url, ssl_context: ssl_context, params: JSON.pretty_generate(request))
          expect(response.code).to eq(403), '/api/permission_requests'
          visit "#{management_url}/api/permission_sets/444444-8888-2849239023"
          expect(page.body.include?('error')).to eq(true), '/api/permission_sets/:sub'
          agreement_term_url = "#{management_url}/agreement_term"
          request = JSON.parse({})
          response = HTTP.post(agreement_term_url, ssl_context: ssl_context, params: JSON.pretty_generate(request))
          expect(response.code).to eq(403), '/api/permission_requests'
        end
        it 'will restrict access to' do
          visit "#{management_url}/api/user/13"
          expect(page.body.include?('error')).to eq(true), '/api/user'
        end
      end
    end
  end
end
