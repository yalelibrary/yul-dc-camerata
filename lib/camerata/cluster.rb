# frozen_string_literal: true
# rubocop:disable Metrics/MethodLength
module Camerata
  class Cluster < Camerata::Parameters
    def self.parameters
      %w[
        VPN
        SAMPLE_BUCKET
        OCR_DOWNLOAD_BUCKET
        ACCESS_DOWNLOAD_BUCKET
        S3_SOURCE_BUCKET_NAME
        S3_DOWNLOAD_BUCKET_NAME
        METADATA_CLOUD_HOST
        PRESERVICA_HOST
        BLACKLIGHT_PASSWORD_PROTECT
        BLACKLIGHT_BASE_URL
        FEATURE_FLAGS
        GOOBI_MOUNT
        GOOBI_SCAN_DIRECTORIES
        IIIF_IMAGE_BASE_URL
        IIIF_MANIFESTS_BASE_URL
        PDF_BASE_URL
        ARCHIVES_SPACE_BASE_URL
        INGEST_ERROR_EMAIL
        IIIF_JAVA_OPTS
        SOLR_HEAP
      ]
    end
  end
end
# rubocop:enable Metrics/MethodLength
