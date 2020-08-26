# frozen_string_literal: true
module Camerata
  class Parameters
    # key can be any list of names, comma seperated
    def self.get(key)
      raise 'please set your AWS_PROFILE and AWS_DEFAULT_REGION' unless ENV['AWS_DEFAULT_REGION'] && ENV['AWS_PROFILE']
      key = "\"#{key}\"" unless key.match?('"')
      result = call_aws_ssm(key)
      JSON.parse(result) if result && !result.empty?
    end

    def self.call_aws_ssm(key)
      `aws ssm get-parameters --names #{key}`
    end

    # rubocop:disable Naming/AccessorMethodName
    def self.get_hash(key)
      json = get(key)
      hash = {}
      json["Parameters"].each do |p|
        key = p['Name']
        value = p['Value']
        hash[key] = value
      end
      hash
    end

    def self.get_all(namespace)
      parameter_string = parameters.map do |v|
        # Pass prefix with namespace if it is provided
        if namespace.strip.empty?
          "\"#{v}\""
        else
          "\"#{namespace}_#{v}\""
        end
      end
      parameter_string = parameter_string.join(" ")
      get_hash(parameter_string)
    end
    # rubocop:enable Naming/AccessorMethodName

    def self.set(key, value, secret = false)
      puts "Setting #{key} param value to #{value}. Secret: #{secret}"
      raise 'please set your AWS_PROFILE and AWS_DEFAULT_REGION' unless ENV['AWS_DEFAULT_REGION'] && ENV['AWS_PROFILE']
      type = secret ? 'SecureString' : 'String'
      result = `aws ssm put-parameter --name "#{key}" --type #{type} --value "#{value}" --overwrite`
      JSON.parse(result) if result && !result.empty?
    end

    def self.load_env
      get_all.each do |k, v|
        ENV[k] = v unless ENV[k] && !ENV[k].empty?
      end
      ENV
    end

    def self.write_dot_file(file_path)
      File.open(file_path, 'w') do |f|
        f.puts("# Written by Camerata v#{Camerata::VERSION} at #{Time.zone.now}")
        get_all.each do |k, v|
          f.puts("#{k}=#{v}")
        end
      end
    end

    # rubocop:disable Naming/AccessorMethodName
    def self.set_from_dot_file(file_path = '.env', secret = false)
      results = []
      File.read(file_path).each_line do |line|
        next if /^#/.match?(line)
        key, value = line.split('=')
        results << set(key.strip, value.strip, secret) if key && value
      end
    end
    # rubocop:enable Naming/AccessorMethodName
  end
end
