# frozen_string_literal: true
module Camerata
  class Cluster < Camerata::Parameters
    def self.parameters
      %w[
        VPN
        SAMPLE_BUCKET
        S3_SOURCE_BUCKET_NAME
        METADATA_CLOUD_HOST
        BLACKLIGHT_PASSWORD_PROTECT
        BLACKLIGHT_BASE_URL
        IIIF_IMAGE_BASE_URL
        IIIF_MANIFESTS_BASE_URL
        LD_PRELOAD
      ]
    end
  end
end
