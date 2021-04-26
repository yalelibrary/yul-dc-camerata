# frozen_string_literal: true
module Camerata
  class Cluster < Camerata::Parameters
    def self.parameters
      %w[
        VPN
        SAMPLE_BUCKET
        OCR_DOWNLOAD_BUCKET
        ACCESS_DOWNLOAD_BUCKET
        S3_SOURCE_BUCKET_NAME
        METADATA_CLOUD_HOST
        BLACKLIGHT_PASSWORD_PROTECT
        BLACKLIGHT_BASE_URL
        GOOBI_MOUNT
        IIIF_IMAGE_BASE_URL
        IIIF_MANIFESTS_BASE_URL
        PDF_BASE_URL
      ]
    end
  end
end
