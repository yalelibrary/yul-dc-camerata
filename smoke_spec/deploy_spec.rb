# frozen_string_literal: true
require_relative './smoke_helper'

blacklight_url = case ENV['CLUSTER_NAME']
                 when 'yul-dc-prod'
                   "https://collections.library.yale.edu"
                 when 'yul-dc-uat'
                   "https://collections-uat.library.yale.edu"
                 when 'yul-dc-test'
                   "https://collections-test.library.yale.edu"
                 when 'yul-dc-demo'
                   "https://collections-demo.library.yale.edu"
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

  case ENV['CLUSTER_NAME']
  when 'yul-dc-prod'
    public_fulltext_parent_oid = '12479735'
    public_fulltext_child_oid = '14997136'
    owp_fulltext_parent_oid = '11785488'
    owp_fulltext_child_oid = '12137988'
    owp_parent_oid = '12481032'
    owp_child_oid = '15212076'
    # yco_fulltext_parent_oid = '2043304'
    # yco_fulltext_child_oid = '1191792'
  when 'yul-dc-uat'
    public_fulltext_parent_oid = '16735206'
    public_fulltext_child_oid = '16735207'
    owp_fulltext_parent_oid = '11785488'
    owp_fulltext_child_oid = '12137988'
    owp_parent_oid = '12481032'
    owp_child_oid = '15212076'
    yco_fulltext_parent_oid = '900048109'
    yco_fulltext_child_oid = '900048120'
  when 'yul-dc-test'
    public_fulltext_parent_oid = '800047436'
    public_fulltext_child_oid = '800047438'
    owp_fulltext_parent_oid = '800048301'
    owp_fulltext_child_oid = '800048302'
    owp_parent_oid = '800049872'
    owp_child_oid = '800049874'
    yco_fulltext_parent_oid = '11492783'
    yco_fulltext_child_oid = '11494521'
  when 'yul-dc-demo'
    public_fulltext_parent_oid = '16747985'
    public_fulltext_child_oid = '16748377'
    owp_fulltext_parent_oid = '11690527'
    owp_fulltext_child_oid = '11690817'
    owp_parent_oid = '15238597'
    owp_child_oid = '15239177'
    # yco_fulltext_parent_oid = '2043304'
    # yco_fulltext_child_oid = '1191792'
  else
    public_fulltext_parent_oid = '800047436'
    public_fulltext_child_oid = '800047438'
    owp_fulltext_parent_oid = '11785488'
    owp_fulltext_child_oid = '12137988'
    owp_parent_oid = '800049872'
    owp_child_oid = '800049874'
    yco_fulltext_parent_oid = '11492783'
    yco_fulltext_child_oid = '11494521'
  end

  describe "The blacklight site at #{blacklight_url}" do
    let(:uri) { "#{blacklight_url}/catalog" }
    context 'when on campus' do
      it 'loads the search page for deployed environments' do
        response = HTTP.get(uri)
        expect(response.body).to have_selector('.blacklight-catalog'), 'not blocked by basic auth'
        expect(response.body).to have_selector('.blacklight-language_ssim'), 'a language facet is present'
        expect(response.body).to have_selector('.branch-name', text: /Branch:\w+/)
        response = HTTP.get("#{uri}?search_field=all_fields&q=")
        expect(response.body).to have_selector("[aria-label='Go to page 5']"), 'an open search has at least 5 pages'
      end
      it 'has a valid SSL certificate' do
        response = HTTP.get(uri)
        expect(response.code).to eq(200)
      end
      describe 'has a public item' do
        it 'that shows Universal Viewer' do
          response = HTTP.get("#{blacklight_url}/catalog/#{public_parent_oid}")
          expect(response.body).to have_selector('.show-header')
          expect(response.body).to have_selector('.universal-viewer-iframe')
        end
      end
      describe 'has a yale-only item' do
        it 'that shows Universal Viewer' do
          response = HTTP.get("#{blacklight_url}/catalog/#{yco_parent_oid}")
          expect(response.body).to have_selector('.show-header')
          expect(response.body).to have_selector('.universal-viewer-iframe')
        end
      end
      describe "The manifest service at #{iiif_manifest_url}" do
        describe 'can provide a manifest' do
          it 'for Public item and links to the manifest' do
            response = HTTP.get("#{blacklight_url}/catalog/#{public_parent_oid}")
            expect(response.body).to have_content('Manifest')
            response = HTTP.get("#{blacklight_url}/manifests/#{public_parent_oid}\.json",
                          ssl_context: ssl_context)
            expect(JSON.parse(response.body)['items'].length).to eq(2),
              'sequence contains two canvases'
          end
          it 'for YCO item and links to the manifest' do
            show_uri = "#{blacklight_url}/catalog/#{yco_parent_oid}"
            response = HTTP.get(show_uri, ssl_context: ssl_context)
            expect(response.body).to have_content('Manifest')
            manifest_uri = "#{blacklight_url}/manifests/#{yco_parent_oid}\.json"
            response = HTTP.get(manifest_uri, ssl_context: ssl_context)
            expect(JSON.parse(response.body)['items'].length).to eq(1),
              'sequence contains one canvas'
          end
          it 'except for OWP items and will not have link' do
            uri = "#{blacklight_url}/manifests/#{owp_parent_oid}\.json"
            response = HTTP.get("#{blacklight_url}/catalog/#{owp_parent_oid}")
            expect(response.body).to have_css('.nav-link.not-found.iiif-logo')
            response = HTTP.get(uri, ssl_context: ssl_context)
            expect(JSON.parse(response.body)).to eq({ 'error' => 'unauthorized' }),
              'no manifest or manifest link'
          end
        end
      end
      describe "The iiif service at #{iiif_image_url}" do
        describe 'info.json' do
          it 'serves an info.json for Public image that has a width/height ratio between 1.5 and 1.7' do
            uri = "#{iiif_image_url}/iiif/2/#{public_child_oid}/info.json"
            response = HTTP.get(uri, ssl_context: ssl_context)
            expect(response.code).to eq(200)
            parsed = JSON.parse(response.body)
            expect(parsed['width'].to_f / parsed['height'].to_f).to be_between(1.5, 1.7).inclusive
          end
        end
        describe 'default.jpg' do
          it 'serves a jpg for Public image' do
            uri = "#{iiif_image_url}/iiif/2/#{public_child_oid}/full/!200,200/0/default.jpg"
            response = HTTP.get(uri, ssl_context: ssl_context)
            expect(response.code).to eq(200)
            expect(response.mime_type).to eq 'image/jpeg'
            # expect(response['Content-Disposition']).to eq("inline; filename=\"1030368.jpg\"")
          end
          it 'serves a jpg for YCO image' do
            uri = "#{iiif_image_url}/iiif/2/#{yco_child_oid}/full/!200,200/0/default.jpg"
            response = HTTP.get(uri, ssl_context: ssl_context)
            expect(response.code).to eq(200)
            expect(response.mime_type).to eq 'image/jpeg'
            # expect(response['Content-Disposition']).to eq("inline; filename=\"1191792.jpg\"")
          end
          it 'does not serve a jpg for OWP image' do
            uri = "#{iiif_image_url}/iiif/2/#{owp_child_oid}/full/!200,200/0/default.jpg"
            response = HTTP.get(uri, ssl_context: ssl_context)
            expect(response.code).to eq(401)
            expect(response.mime_type).to eq 'text/html'
          end
        end
      end
      describe 'annotations' do
        it 'serves an annotation for Public image' do
          uri = "#{blacklight_url}/annotation/oid/#{public_fulltext_parent_oid}/canvas/#{public_fulltext_child_oid}/fulltext?oid=#{public_fulltext_parent_oid}&child_oid=#{public_fulltext_child_oid}"
          response = HTTP.get(uri, ssl_context: ssl_context)
          expect(response.code).to eq(200)
          expect(JSON.parse(response.body)['type']).to eq 'Annotation'
        end
        # no yco fulltext in prod or demo
        if ENV['CLUSTER_NAME'] == 'yul-dc-uat' || ENV['CLUSTER_NAME'] == 'yul-dc-test'
          it 'serves an annotation for YCO image' do
            uri = "#{blacklight_url}/annotation/oid/#{yco_fulltext_parent_oid}/canvas/#{yco_fulltext_child_oid}/fulltext?oid=#{yco_fulltext_parent_oid}&child_oid=#{yco_fulltext_child_oid}"
            response = HTTP.get(uri, ssl_context: ssl_context)
            expect(response.code).to eq(200)
            expect(JSON.parse(response.body)['type']).to eq 'Annotation'
          end
        end
        it 'does not serve an annotation for OWP image' do
          uri = "#{blacklight_url}/annotation/oid/#{owp_fulltext_parent_oid}/canvas/#{owp_fulltext_child_oid}/fulltext?oid=#{owp_fulltext_parent_oid}&child_oid=#{owp_fulltext_child_oid}"
          response = HTTP.get(uri, ssl_context: ssl_context)
          expect(response.code).to eq(401), 'has unauthorized response'
          expect(JSON.parse(response.body)).to eq({ 'error' => 'unauthorized' })
        end
      end
      describe 'tiff download' do
        it 'for Public image' do
          action_uri = "#{blacklight_url}/download/tiff/#{public_child_oid}/staged"
          retrieval_uri = "#{blacklight_url}/download/tiff/#{public_child_oid}"
          response = HTTP.get(action_uri, ssl_context: ssl_context)
          expect(response.code).to eq(200), 'has success response'
          response = HTTP.get(retrieval_uri, ssl_context: ssl_context)
          expect(response.mime_type).to eq('image/tiff').or eq('text/html')
          expect(response.code).to eq(303).or eq(200)
        end
        it 'for YCO image' do
          action_uri = "#{blacklight_url}/download/tiff/#{yco_child_oid}/staged"
          retrieval_uri = "#{blacklight_url}/download/tiff/#{yco_child_oid}"
          response = HTTP.get(action_uri, ssl_context: ssl_context)
          expect(response.code).to eq(200), 'has success response'
          response = HTTP.get(retrieval_uri, ssl_context: ssl_context)
          expect(response.mime_type).to eq('image/tiff').or eq('text/html')
          expect(response.code).to eq(303).or eq(200)
        end
        it 'for OWP image' do
          action_uri = "#{blacklight_url}/download/tiff/#{owp_child_oid}/staged"
          retrieval_uri = "#{blacklight_url}/download/tiff/#{owp_child_oid}"
          response = HTTP.get(action_uri, ssl_context: ssl_context)
          expect(response.code).to eq(401), 'has unauthorized response'
          response = HTTP.get(retrieval_uri, ssl_context: ssl_context)
          expect(response.code).to eq(401), 'does not serve a tiff'
        end
      end
      describe 'pdfs' do
        it 'serves a pdf for Public image' do
          response = HTTP.get("#{blacklight_url}/pdfs/#{public_parent_oid}.pdf", ssl_context: ssl_context)
          expect(response.code).to eq(200)
          expect(response.mime_type).to eq 'application/pdf'
        end
        it 'serves a pdf for YCO image' do
          response = HTTP.get("#{blacklight_url}/pdfs/#{yco_parent_oid}.pdf", ssl_context: ssl_context)
          expect(response.code).to eq(200)
          expect(response.mime_type).to eq 'application/pdf'
        end
        it 'does not serve a pdf for OWP image' do
          response = HTTP.get("#{blacklight_url}/pdfs/#{owp_parent_oid}.pdf", ssl_context: ssl_context)
          expect(response.code).to eq(401), 'has unauthorized response'
          expect(response.mime_type).to eq 'application/json'
        end
      end
      describe 'owp request service' do
        let(:request_uri) { "#{blacklight_url}/catalog/#{owp_parent_oid}/request_form" }
        let(:terms_uri) { "#{blacklight_url}/catalog/#{owp_parent_oid}/terms_and_conditions" }
        let(:confirmation_uri) { "#{blacklight_url}/catalog/#{owp_parent_oid}/request_confirmation" }
        it 'will not be accessible' do
          response = HTTP.get(request_uri, ssl_context: ssl_context)
          expect(response.code).to eq(302), 'request form redirect has found response'
          expect(response.headers["Location"]).to eq("#{blacklight_url}/catalog/#{owp_parent_oid}"), 'request form redirects to parent object page'
          expect(response.body.include?("uv")).to eq(false), 'request form does not display UV for object'
          response = HTTP.get(terms_uri, ssl_context: ssl_context)
          expect(response.code).to eq(404), 'terms api has not found response'
          response = HTTP.get(confirmation_uri, ssl_context: ssl_context)
          expect(response.code).to eq(302), 'request confirmation redirect has found response'
          expect(response.headers["Location"]).to eq("#{blacklight_url}/catalog/#{owp_parent_oid}"), 'request confirmation redirects to parent object page'
          expect(response.body.include?("uv")).to eq(false), 'request confirmation does not display UV for object'
        end
      end
    end
  end
  describe "The management site at #{management_url}" do
    # This information is now protected behind CAS authentication.
    # Removing this test for now. We will restore it when we have a CAS account.
    xit 'has version numbers in the table' do
      response = HTTP.get(management_url)
      expect(response.body).to have_selector('#management_version', text: /v\d+.\d+.\d+/)
      expect(response.body).to have_selector('#postgres_version', text: /v\d+.\d+.\d+/)
      expect(response.body).to have_selector('#blacklight_version', text: /v\d+.\d+.\d+/)
      expect(response.body).to have_selector('#solr_version', text: /v\d+.\d+.\d+/)
      expect(response.body).to have_selector('#iiif_image_version', text: /v\d+.\d+.\d+/)
      expect(response.body).to have_selector('#iiif_manifest_version', text: /v\d+.\d+.\d+/)
      expect(response.body).to have_selector('#camerata_version', text: /v\d+.\d+.\d+/)
    end
    it 'prompts the user to sign in' do
      response = HTTP.get(management_url)
      expect(response.body).to have_button('You must sign in')
    end
    describe '/api' do
      context 'when on campus' do
        it 'will restrict access to staging downloads of Public images' do
          response = HTTP.get("#{management_url}/api/download/stage/child/#{public_child_oid}")
          expect(response.code).to eq 403
        end
        it 'will restrict access to staging downloads of YCO images' do
          response = HTTP.get("#{management_url}/api/download/stage/child/#{yco_child_oid}")
          expect(response.code).to eq 403
        end
        it 'will restrict access to OWP' do
          response = HTTP.get("#{management_url}/api/download/stage/child/#{owp_child_oid}")
          expect(response.body.to_json.include?('403 Forbidden')).to eq(true), '/api/download/stage/child/:child_oid'
          permission_requests_url = "#{management_url}/api/permission_requests"
          response = HTTP.post(permission_requests_url, ssl_context: ssl_context)
          expect(response.code).to eq(403), '/api/permission_requests'
          response = HTTP.get("#{management_url}/api/permission_sets/444444-8888-2849239023")
          expect(response.body.to_json.include?('403 Forbidden')).to eq(true), '/api/permission_sets/:sub'
          agreement_term_url = "#{management_url}/agreement_term"
          response = HTTP.post(agreement_term_url, ssl_context: ssl_context)
          expect(response.code).to eq(403).or eq(401)
          expect(response.code).not_to eq(200), '/agreement_term'
        end
        it 'will restrict access to users' do
          response = HTTP.get("#{management_url}/api/user/13")
          expect(response.code).to eq 403
        end
      end
    end
  end
end
