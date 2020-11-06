# frozen_string_literal: true
module Camerata
  class Parameters
    # key can be any list of up to ten names, separated by spaces
    def self.get(key)
      raise 'please set your AWS_PROFILE and AWS_DEFAULT_REGION' unless ENV['AWS_DEFAULT_REGION'] && ENV['AWS_PROFILE']
      key = "\"#{key}\"" unless key.match?('"')
      result = call_aws_ssm(key)
      JSON.parse(result) if result && !result.empty?
    end

    def self.get_list(parameter_list)
      raise 'please set your AWS_PROFILE and AWS_DEFAULT_REGION' unless ENV['AWS_DEFAULT_REGION'] && ENV['AWS_PROFILE']
      result_list = []
      parameter_list.each_slice(10) do |slice|
        result = call_aws_ssm(slice.join(" "))
        result_list << JSON.parse(result) if result && !result.empty?
      end
      result_list
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
      # Returns the new param name with /target_ns/ prefixed to base
      stripped_name = name.sub(/^\/#{Regexp.escape(source_ns)}\//, '')
      return stripped_name unless target_ns
      "/#{target_ns}/#{stripped_name}"
    end

    def self.pull_parameter_hash(parameter_list, namespace = nil)
      json_list = get_list(parameter_list)
      hash = {}
      json_list.each do |json|
        json["Parameters"].each do |p|
          # Remove namespace before setting key
          key = if namespace
                  p['Name'].sub(/^\/#{Regexp.escape(namespace)}\//, '')
                else
                  p['Name']
                end
          value = p['Value']
          hash[key] = value
        end
      end
      hash
    end

    def self.get_all(namespace = "")
      parameter_list = parameters.map do |v|
        "\"#{v}\""
      end
      # Create both versions of param string
      default_parameter_hash = pull_parameter_hash(parameter_list, namespace)
      return default_parameter_hash if namespace.empty?

      parameter_list = parameters.map do |p|
        "\"/#{namespace}/#{p}\""
      end
      namespaced_parameter_hash = pull_parameter_hash(parameter_list, namespace)
      default_parameter_hash.merge(namespaced_parameter_hash)
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

    def self.load_env(namespace)
      get_all(namespace).each do |k, v|
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
