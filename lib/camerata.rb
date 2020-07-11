# frozen_string_literal: true
require "camerata/version"
require "camerata/parameters"
require "camerata/app_versions"
require "camerata/secrets"
require 'thor'
require 'erb'
require 'json'
require 'active_support'
require 'yaml'
require 'byebug'

# rubocop:disable Metrics/ClassLength
module Camerata
  class Error < StandardError; end
  class CLI < Thor
    include Thor::Actions

    def self.source_root
      File.join(File.dirname(__FILE__), '..', 'templates')
    end

    def self.exit_on_failure?
      true
    end

    method_option :without, default: '', type: :string, aliases: '-no'
    desc "up", "starts docker-compose with orphan removal, defaults to blacklight"
    def up(*args)
      ensure_env
      output = default_options(args, ['--remove-orphans'])
      run_with_exit("#{docker_compose} up #{output.join(' ')}")
    end

    desc "stop", "stops the specified running service, defaults to all"
    def stop(*args)
      ensure_env
      run("#{docker_compose} stop #{args.join(' ')}")
      run_with_exit("rm -rf tmp/pids/*")
    end

    desc "restart", "restarts the specified running service, defaults to all"
    def restart(*args)
      ensure_env
      run_with_exti("#{docker_compose} restart #{args.join(' ')}")
    end

    desc "down", "complete down, removes containers, volumes and orphans"
    def down
      ensure_env
      output = ['--remove-orphans', '-v']
      run("#{docker_compose} down #{output.join(' ')}")
      run_with_exit("rm -rf tmp/pids/*")
    end

    desc "build", "builds specified service, defaults to blacklight"
    def build(*args)
      ensure_env
      options = default_options(args)
      run_with_exit("#{docker_compose} build #{options.join(' ')}")
    end

    desc "push ARGS", "wraps docker-compose push"
    def push(*args)
      ensure_env
      run_with_exit("#{docker_compose} push #{args.join(' ')}")
    end

    desc "pull ARGS", "wraps docker-compose pull"
    def pull(*args)
      ensure_env
      run_with_exit("#{docker_compose} pull #{args.join(' ')}")
    end

    desc "ps ARGS", "wraps docker-compose status"
    def ps(*args)
      ensure_env
      run_with_exit("#{docker_compose} ps #{args.join(' ')}")
    end
    map status: :ps

    desc "bundle SERVICE", "runs bundle inside the running container, specify the serivce as blacklight or management"
    def bundle(service = 'blacklight')
      ensure_env
      run_with_exit("#{docker_compose} exec #{service} bundle")
    end

    desc "walk ARGS", "wraps docker-compose run, 'run' is not an allowed thor command, thus walk"
    def walk(*args)
      ensure_env
      options = default_options(args)
      run_with_exit("#{docker_compose} run #{options.join(' ')}")
    end

    desc "exec ARGS", "wraps docker-compose exec"
    def exec(*args)
      ensure_env
      options = default_options(args)
      run_with_exit("#{docker_compose} exec #{options.join(' ')}")
    end
    map ex: :exec

    desc 'sh ARGS', "launch a shell using docker-compose exec, sets tty properly"
    def sh(*args)
      ensure_env
      options = default_options(args, ["-e COLUMNS=\"\`tput cols\`\" -e LINES=\"\`tput lines\`\""])
      run_with_exit("#{docker_compose} exec #{options.join(' ')} bundle exec bash")
    end

    desc "bundle_exec ARGS", "wraps docker-compose exec SERVICE bundle exec ARGS"
    def bundle_exec(service, *args)
      ensure_env
      run_with_exit("#{docker_compose} exec #{service} bundle exec #{args.join(' ')}")
    end
    map be: :bundle_exec

    desc "console ARGS", "shortcut to start rails console"
    def console(service, *args)
      ensure_env
      run_with_exit("#{docker_compose} exec #{service} bundle exec rails console #{args.join(' ')}")
    end
    map rc: :console

    desc "smoke ARGS", "Run the smoke tests against a running stack"
    def smoke(*args)
      run_with_exit("rspec #{smoke_path} #{args.join(' ')}")
    end

    desc 'version', 'print the current version'
    def version
      say "Camerata Version: #{Camerata::VERSION}"
    end

    def method_missing(meth, *args) # rubocop:disable Style/MethodMissingSuper
      # Check if a .sh script exists for this command
      bin_path = bin_path_for_method(meth)
      if bin_exists?(meth)
        ensure_env('ecs')
        cmd = (["COMPOSE_FILE=#{compose_path}", bin_path] + args).join(' ')
        run(cmd)
      else
        super(meth, args)
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      bin_exists?(method_name) || super
    end

    private

    def bin_path_for_method(meth)
      method = meth.to_s.gsub(/.sh$/, '')
      File.expand_path(File.join(__dir__, '..', 'bin', "#{method}.sh"))
    end

    def bin_exists?(meth)
      File.exist?(bin_path_for_method(meth))
    end

    def run_with_exit(*args)
      result = run(*args)
      exit(1) unless result
    end

    def merge_compose(out, *inputs)
      result = {}
      inputs.each do |input|
        file_path = File.join(self.class.source_root, input)
        content = ERB.new(::File.binread(file_path), nil, "-", "@output_buffer").result(binding)
        input_yaml = YAML.safe_load(content)
        result.deep_merge!(input_yaml)
      end
      File.open(out, 'w') do |file|
        file.write(YAML.dump(result))
      end
    end

    def smoke_path
      @smoke_path ||= File.expand_path(File.join(__dir__, '..', 'smoke_spec'))
    end

    def compose_path
      @compose_path ||= File.expand_path(File.join(__dir__, '..', 'tmp', 'docker-compose.yml'))
    end

    # rubocop:disable Metrics/MethodLength
    def build_compose(type)
      build_files = [
        "blacklight-compose.yml",
        "blacklight-compose.#{type}.yml",
        "iiif-images-compose.yml",
        "iiif-images-compose.#{type}.yml",
        "iiif-manifest-compose.yml",
        "iiif-manifest-compose.#{type}.yml",
        "management-compose.yml",
        "management-compose.#{type}.yml"
      ]

      if type == 'local'
        build_files += [
          "db-compose.yml",
          "db-compose.#{type}.yml",
          "solr-compose.yml",
          "solr-compose.#{type}.yml"
        ]
      end

      merge_compose(compose_path, *build_files)
    end
    # rubocop:enable Metrics/MethodLength

    def in_blacklight?
      file = File.join('config', 'application.rb')
      File.exist?(file) && File.open(file).grep('BlacklightYul')
    end

    def in_management?
      file = File.join('config', 'application.rb')
      File.exist?(file) && File.open(file).grep('YulDcManagement')
    end

    def without
      options[:without] || ''
    end

    def secrets_path(type)
      if type == 'ecs'
        File.expand_path(File.join(__dir__, '..', 'tmp', '.secrets'))
      else
        '.secrets'
      end
    end

    def env_path(type)
      if type == 'ecs'
        File.expand_path(File.join(__dir__, '..', 'tmp', '.env'))
      else
        '.env'
      end
    end

    def ensure_env(type = 'local')
      # TODO: remove writing these files once the env is confirmed all in memory
      template(".secrets.erb", secrets_path(type)) unless File.exist?(secrets_path(type))
      template(".env.erb", env_path(type)) unless File.exist?(env_path(type))
      Camerata::AppVersions.load_env
      Camerata::Secrets.load_env
      build_compose(type)
    end

    def docker_compose
      "docker-compose --project-directory . -f #{compose_path}"
    end

    def default_options(args, output = [])
      if args.empty?
        output << 'blacklight'
      else
        output + args
      end
    end
  end
end
# rubocop:enable Metrics/ClassLength
