# frozen_string_literal: true
module Camerata
  class Secrets < Camerata::Parameters
    # rubocop:disable Metrics/MethodLength
    def self.parameters
      %w[
        CANTALOUPE_VERSION
        DEPLOY_ACCESS_KEY
        DEPLOY_KEY_ID
        HONEYBADGER_API_KEY_BLACKLIGHT
        HONEYBADGER_API_KEY_IMAGESERVER
        HONEYBADGER_API_KEY_MANAGEMENT
        HTTP_PASSWORD
        HTTP_USERNAME
        MC_PW
        MC_USER
        OWP_AUTH_TOKEN
        POSTGRES_DB
        POSTGRES_HOST
        POSTGRES_MULTIPLE_DATABASES
        POSTGRES_PASSWORD
        POSTGRES_USER
        PRESERVICA_CREDENTIALS
        RAILS_MASTER_KEY
        SSO_ID
        SSO_ISS
        SSO_HOST
        SSO_JWKS
        SSO_SECRET
        SOLR_BASE_URL
        SOLR_URL
        SOLR_URL_WITH_CORE
        YALE_NETWORK_IPS
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
