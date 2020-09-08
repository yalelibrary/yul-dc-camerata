# frozen_string_literal: true
module Camerata
  class Secrets < Camerata::Parameters
    def self.parameters
      %w[
        HONEYBADGER_API_KEY_BLACKLIGHT
        HONEYBADGER_API_KEY_IMAGESERVER
        HONEYBADGER_API_KEY_MANAGEMENT
        HTTP_PASSWORD
        HTTP_USERNAME
        RAILS_MASTER_KEY
      ]
    end

    def self.get(key)
      raise 'please set your AWS_PROFILE and AWS_DEFAULT_REGION' unless ENV['AWS_DEFAULT_REGION'] && ENV['AWS_PROFILE']
      key = "\"#{key}\"" unless key.match?('"')
      result = call_aws_ssm(key)
      JSON.parse(result) if result && !result.empty?
    end

    def self.call_aws_ssm(key)
      `aws ssm get-parameters --names #{key} --with-decryption`
    end

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
