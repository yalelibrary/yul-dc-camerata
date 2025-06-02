# frozen_string_literal: true
module Camerata
  class Secrets < Camerata::Parameters
    # rubocop:disable Metrics/MethodLength
    def self.parameters
      %w[
        HONEYBADGER_API_KEY_BLACKLIGHT
        HONEYBADGER_API_KEY_IMAGESERVER
        HONEYBADGER_API_KEY_MANAGEMENT
        HTTP_PASSWORD
        HTTP_USERNAME
        MC_USER
        MC_PW
        PRESERVICA_CREDENTIALS
        RAILS_MASTER_KEY
        CANTALOUPE_VERSION
        DYNATRACE_TOKEN
        DEPLOY_KEY_ID
        DEPLOY_ACCESS_KEY
        OWP_AUTH_TOKEN
        YALE_NETWORK_IPS
        SSO_ID
        SSO_HOST
        SSO_SECRET
        SSO_JWKS
        SSO_ISS
        SOLR_URL
        SOLR_BASE_URL
        SOLR_URL_WITH_CORE
      ]
    end
    # rubocop:enable Metrics/MethodLength

    # rubocop:disable Naming/AccessorMethodName
    def self.get_all(namespace = "")
      hash = super
      hash['AWS_SECRET_ACCESS_KEY'] = aws_secret_access_key
      hash['AWS_ACCESS_KEY_ID'] = aws_access_key_id
      hash
    end
    # rubocop:enable Naming/AccessorMethodName

    def self.aws_secret_access_key
      `aws configure get aws_secret_access_key`.strip
    end

    def self.aws_access_key_id
      `aws configure get aws_access_key_id`.strip
    end
  end
end
