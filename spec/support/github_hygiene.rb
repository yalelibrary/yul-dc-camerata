# frozen_string_literal: true

module GithubHygiene
  RSpec.configure do |config|
    config.after(:each, type: :github_api) do
      unless ENV['CI']
        # Read through each .yml file in the VCR cassettes directory and replace token string with xxx
        Dir.glob(File.join(__dir__, '..', 'fixtures', 'vcr_cassettes', '*.yml')).each do |file|
          tfile = Tempfile.new(File.basename(file))
          File.open(file, 'r') do |f|
            f.each_line do |line|
              tfile.puts line.gsub(ENV['CHANGELOG_GITHUB_TOKEN'], 'xxxxx')
            end
          end
          tfile.close
          FileUtils.mv(tfile.path, file)
        end
      end
    end
  end
end
