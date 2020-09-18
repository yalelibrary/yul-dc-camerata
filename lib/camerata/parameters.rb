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
      `aws ssm get-parameters --names #{key} --with-decryption`
    end

    def self.copy_param_set(group, target_ns, source_ns)
      group.each do |name, version|
        set(create_param_name(target_ns, source_ns, name), version)
      end
    end

    def self.create_param_name(target_ns, source_ns, name)
      # Gets param name base by removing any ns prefixes from param name
      # param_base of "/YUL_TEST/BLACKLIGHT_VERSION" --> "BLACKLIGHT_VERSION"
      # param_base defaults to name if source_ns is empty
      param_base = source_ns.strip.empty? ? name : name.split("/#{source_ns}/")[1]
      # Returns the new param name with /target_ns/ prefixed to base
      "/#{target_ns}/#{param_base}"
    end

    # rubocop:disable Naming/AccessorMethodName
    def self.pull_parameter_hash(key, namespace)
      json = get(key)
      hash = {}
      json["Parameters"].each do |p|
        # Remove namespace before setting key
        key = p['Name'].sub(/^\/#{Regexp.escape(namespace)}\//, '')
        value = p['Value']
        hash[key] = value
      end
      hash
    end

    def self.get_all(namespace = "")
      parameter_list = parameters.map do |v|
        # Pass prefix with namespace if it is provided
        # Create both versions of param string
        # Use sub verion: sub(/^\/#{Regexp.escape(namespace)}\//, '')
        "\"#{v}\""
      end
      namespaced_parameter_hash = pull_parameter_hash(parameter_list.join(" "), namespace)
      parameter_list = parameter_list.map do |p|
        p.sub(/^\/#{Regexp.escape(namespace)}\//, '')
      end
      default_parameter_hash = pull_parameter_hash(parameter_list.join(" "), namespace)
      namespaced_parameter_hash.merge(default_parameter_hash)
    end
    # rubocop:enable Naming/AccessorMethodName

    def self.set(key, value, secret = false)
      puts "Setting #{key} param value to #{value}. Secret: #{secret}"
      raise 'please set your AWS_PROFILE and AWS_DEFAULT_REGION' unless ENV['AWS_DEFAULT_REGION'] && ENV['AWS_PROFILE']
      result = put_parameter(key, value, secret)
      JSON.parse(result) if result && !result.empty?
    end

    def self.put_parameter(key, value, secret = false)
      type = secret ? 'SecureString' : 'String'
      `aws ssm put-parameter --name "#{key}" --type #{type} --value "#{value}" --overwrite`
    end

    # default namespace /BLACKLIGHT_VERSION   cluster-specific namespace /YUL_TEST/BLACKLIGHT_VERSION
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
