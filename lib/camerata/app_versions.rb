# frozen_string_literal: true
module Camerata
  class AppVersions < Camerata::Parameters
    def self.parameters
      %w[
        BLACKLIGHT_VERSION
        IIIF_IMAGE_VERSION
        IIIF_MANIFEST_VERSION
        MANAGEMENT_VERSION
        POSTGRES_VERSION
        SOLR_VERSION
        CAMERATA_VERSION
      ]
    end
  end
end
