# frozen_string_literal: true
require 'thor'
require 'erb'
require 'json'
require 'active_support'
require 'yaml'
require 'byebug'

require "camerata/version"
require "camerata/dot_rc"
require "camerata/parameters"
require "camerata/app_versions"
require "camerata/secrets"
require "camerata/cluster"
require "camerata/taggable_app"

# rubocop:disable Metrics/ClassLength
module Camerata
  @cluster_name = nil
  def self.cluster_name
    @cluster_name ||= ENV['CLUSTER_NAME']
  end

  # TODO: use cluster env variable
  def self.gather_env(source_ns)
    { "app_versions" => Camerata::AppVersions.get_all(source_ns),
      "cluster" => Camerata::Cluster.get_all(source_ns),
      "secrets" => Camerata::Secrets.get_all(source_ns) }
  end

  def self.copy_param_sets(parameter_sets, target_ns, source_ns)
    # Using the list from app_versions, create new params with the target_ns prefixed to param name
    # copy_param_set should be using create_param_name method to create the new namespaced param name
    Camerata::Parameters.copy_param_set(parameter_sets['app_versions'], target_ns, source_ns)
    Camerata::Parameters.copy_param_set(parameter_sets['cluster'], target_ns, source_ns)
    # Using the list from secrets, create new params with the target_ns prefixed to param name
    # Also uses create_param_name to create the new namespaced param name
    parameter_sets['secrets'].each do |key, value|
      # Skip set when looking at AWS Credentials
      Camerata::Parameters.set(Camerata::Parameters.create_param_name(target_ns, source_ns, key), value, true) unless key == "AWS_ACCESS_KEY_ID" || key == "AWS_SECRET_ACCESS_KEY"
    end
  end

  def self.set_version(app_name, version)
    Camerata::AppVersions.set(Parameters.create_param_name(cluster_name, '', app_name), version)
  end

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

    desc "stop", "stops the specified running local service, defaults to all"
    def stop(*args)
      ensure_env
      run("#{docker_compose} stop #{args.join(' ')}")
      run_with_exit("rm -rf tmp/pids/*")
    end

    desc "restart", "restarts the specified running local service, defaults to all"
    def restart(*args)
      ensure_env
      run_with_exit("#{docker_compose} restart #{args.join(' ')}")
    end

    desc "down", "complete local down, removes containers, volumes and orphans"
    def down
      ensure_env
      output = ['--remove-orphans', '-v']
      run("#{docker_compose} down #{output.join(' ')}")
      run_with_exit("rm -rf tmp/pids/*")
    end

    desc "build", "builds specified local service, defaults to blacklight"
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

    desc "logs ARGS", "wraps docker-compose logs"
    def logs(*args)
      ensure_env
      run_with_exit("#{docker_compose} logs #{args.join(' ')}")
    end
    map log: :logs

    method_option :user, default: 'app', type: :string, alias: '-u'
    desc "bundle SERVICE", "runs bundle inside the running container, specify the serivce as blacklight or management"
    def bundle(service = 'blacklight')
      ensure_env
      user = options.dup.delete(:user)
      run_with_exit("#{docker_compose} exec -u #{user} #{service} bundle")
    end

    desc "walk ARGS", "wraps docker-compose run, 'run' is not an allowed thor command, thus walk"
    def walk(*args)
      ensure_env
      options = default_options(args)
      run_with_exit("#{docker_compose} run #{options.join(' ')}")
    end

    method_option :user, default: 'app', type: :string, alias: '-u'
    desc "exec ARGS", "wraps docker-compose exec"
    def exec(*args)
      ensure_env
      user = options.dup.delete(:user)
      options = default_options(args)
      run_with_exit("#{docker_compose} exec -u #{user} #{options.join(' ')}")
    end
    map ex: :exec

    method_option :user, default: 'app', type: :string, alias: '-u'
    desc 'sh ARGS', "launch a shell using docker-compose exec, sets tty properly"
    def sh(*args)
      ensure_env
      user = options.dup.delete(:user)
      options = default_options(args, ["-e COLUMNS=\"\`tput cols\`\" -e LINES=\"\`tput lines\`\""])
      run_with_exit("#{docker_compose} exec -u #{user} #{options.join(' ')} bundle exec bash")
    end

    method_option :user, default: 'app', type: :string, alias: '-u'
    desc "bundle_exec ARGS", "wraps docker-compose exec SERVICE bundle exec ARGS"
    def bundle_exec(service, *args)
      ensure_env
      user = options[:user]
      run_with_exit("#{docker_compose} exec -u #{user} #{service} bundle exec #{args.join(' ')}")
    end
    map be: :bundle_exec

    method_option :user, default: 'app', type: :string, alias: '-u'
    desc "console ARGS", "shortcut to start rails console"
    def console(service, *args)
      ensure_env
      user = options[:user]
      run_with_exit("#{docker_compose} exec -u #{user} #{service} bundle exec rails console #{args.join(' ')}")
    end
    map rc: :console

    desc "env_copy TARGET_NS SOURCE_NS", "copy params from env to another"
    def env_copy(target_ns, source_ns = "")
      # Collect all project variables from the parameter store
      parameter_sets = Camerata.gather_env(source_ns)
      # Output the collected list of app versions and secrets
      # Without source_ns APP VERSIONS: { "BLACKLIGHT_VERSION"=>"v1.15.1", "CAMERATA_VERSION"=>"v2.4.0" ...}
      # With source_ns set to "YUL_DEPLOY" APP VERSIONS: { "YUL_DEPLOY_BLACKLIGHT_VERSION"=>"v1.15.1", "YUL_DEPLOY_CAMERATA_VERSION"=>"v2.4.0" ...}
      puts "\n Copying following parameters from source to #{target_ns} namespace: " \
           "\n App versions: #{parameter_sets['app_versions']}" \
           "\n Cluster specific values: #{parameter_sets['cluster']}" \
           "\n Secrets: #{parameter_sets['secrets']}"
      Camerata.copy_param_sets(parameter_sets, target_ns, source_ns)
    end

    desc "env_get KEY", "get value of a parameter"
    def env_get(key)
      result = Camerata::Parameters.get(key)
      if result["Parameters"].blank?
        puts "The requested #{key} param does not exist"
      else
        puts result["Parameters"][0]["Value"]
      end
    end

    desc "env_set ARGS", "set the value of a parameter"
    def env_set(*args)
      Camerata::Parameters.set(*args)
    end

    desc "smoke ARGS", "Run the smoke tests against a running stack"
    def smoke(*args)
      ensure_env
      run_with_exit("rspec #{smoke_path} #{args.join(' ')}")
    end

    desc "push_version APP VERSION", "Set a new version string for release of an application. For example `cam push_version blacklight v2.5.1`"
    def push_version(app, version)
      app_name = Camerata::AppVersions.parameters.detect { |v| v.match(app.upcase) }
      unless app_name
        puts "Did not find matching version string for #{app}"
        exit(1)
      end
      Camerata.set_version(app_name, version)
    end

    ##
    # Tag a release of a microservice, E.g., cam release blacklight
    # This will:
    # 1. Auto-generate release notes for the new version
    # 2. Determine whether there are any features or breaking changes, and increment the version number accordingly
    # 3. Tag the release in github with the new version number and the release notes
    desc "release APP", "tag a release of a microservice, e.g., cam release blacklight"
    def release(app)
      puts "You must set CHANGELOG_GITHUB_TOKEN. See https://github.com/github-changelog-generator/github-changelog-generator#github-token" unless ENV['CHANGELOG_GITHUB_TOKEN']
      taggable_apps = Camerata::TaggableApp.known_apps
      unless taggable_apps.include? app
        puts "I don't know how to release #{app}."
        puts "I only know how to release these apps: #{taggable_apps}"
        exit(1)
      end
      taggable_app = Camerata::TaggableApp.new(app)
      unless taggable_app.release_needed?
        puts "No new release needed for #{app}"
        exit(0)
      end
      taggable_app.release
      puts "Released #{app} #{taggable_app.new_version_number}"
    end

    desc 'version', 'print the current version'
    def version
      say "Camerata Version: #{Camerata::VERSION}"
    end

    desc 'deploy_main CLUSTER_NAME', 'deploy the main group of microservices to your specified cluster'
    def deploy_main(this_cluster)
      meth = 'deploy-main'
      bin_path = bin_path_for_method(meth)
      @cluster_name = this_cluster
      ensure_env('ecs')
      cmd = (["COMPOSE_FILE=#{compose_path}", bin_path] + args).join(' ')
      run(cmd)
    end
    map 'deploy-main' => :deploy_main

    desc 'deploy_solr CLUSTER_NAME', 'deploy solr to your specified cluster'
    def deploy_solr(*args)
      solr_stopped = ask('You must stop solr before you can redeploy it. Have you stopped your running solr? (y/n)')
      if prep_answer(solr_stopped) != 'y'
        error("Exiting without deploying. You must stop solr before redeploying. Try cam stop-solr CLUSTER_NAME")
        exit(1)
      end
      meth = 'deploy-solr'
      exit(1) unless check_and_run_bin(meth, args)
    end
    map 'deploy-solr' => :deploy_solr

    desc 'deploy_db CLUSTER_NAME', 'deploy the psql database to your specified cluster'
    def deploy_db(*args)
      db_stopped = ask('You must stop the psql database before you can redeploy it.  Have you stopped your running database? (y/n)')
      if prep_answer(db_stopped) != 'y'
        error("Exiting without deploying.  Try cam stop-db CLUSTER_NAME")
        exit(1)
      end
      meth = 'deploy-psql'
      exit(1) unless check_and_run_bin(meth, args)
    end
    map 'deploy-psql' => :deploy_db

    def method_missing(meth, *args) # rubocop:disable Style/MethodMissingSuper
      # Check if a .sh script exists for this command
      if bin_exists?(meth)
        check_and_run_bin(meth, args)
      else
        super(meth, args)
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      bin_exists?(method_name) || super
    end

    private

    def check_and_run_bin(meth, args = [])
      bin_path = bin_path_for_method(meth)
      ensure_env('ecs')
      check_for_special_compose(meth)
      cmd = (["COMPOSE_FILE=#{compose_path}", bin_path] + args).join(' ')
      run(cmd)
    end

    def check_for_special_compose(meth)
      method_name = method_for(meth)
      case method_name
      when 'deploy-psql'
        db_only_compose
      when 'deploy-solr'
        solr_only_compose
      end
    end

    def db_only_compose
      build_files = [
        "db-compose.yml",
        "db-compose.ecs.yml"
      ]
      merge_compose(compose_path, *build_files)
    end

    def solr_only_compose
      build_files = [
        "solr-compose.yml",
        "solr-compose.ecs.yml"
      ]
      merge_compose(compose_path, *build_files)
    end

    def method_for(meth)
      meth.to_s.gsub(/.sh$/, '')
    end

    def bin_path_for_method(meth)
      File.expand_path(File.join(__dir__, '..', 'bin', "#{method_for(meth)}.sh"))
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
      File.exist?(file) && !File.open(file).grep(/BlacklightYul/).empty?
    end

    def in_management?
      file = File.join('config', 'application.rb')
      File.exist?(file) && !File.open(file).grep(/YulDcManagement/).empty?
    end

    def in_manifest?
      file = File.join('config', 'application.rb')
      File.exist?(file) && !File.open(file).grep(/YulDcIiifManifest/).empty?
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

    ##
    # Generate secrets and .env files that are expected by deploy scripts and
    # docker-compose files
    def ensure_env(type = 'local')
      DotRc.new
      # TODO: remove writing these files once the env is confirmed all in memory
      template(".secrets.erb", secrets_path(type)) unless File.exist?(secrets_path(type))
      template(".env.erb", env_path(type)) unless File.exist?(env_path(type))
      Camerata::AppVersions.load_env
      Camerata::Secrets.load_env
      Camerata::Cluster.load_env
      build_compose(type)
    end

    def docker_compose
      "docker-compose --project-directory . -f #{compose_path}"
    end

    def prep_answer(answer)
      answer.to_s.downcase.strip
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
