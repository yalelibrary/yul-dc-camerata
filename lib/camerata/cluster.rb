# frozen_string_literal: true
module Camerata
  class Cluster < Camerata::Parameters
    def self.parameters
      %w[
        VPN
        SAMPLE_BUCKET
        S3_SOURCE_BUCKET_NAME
        METADATA_CLOUD_HOST
      ]
    end
  end
end
