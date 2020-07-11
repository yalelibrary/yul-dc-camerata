# frozen_string_literal: true
module Capture
  # Captures the output for analysis later
  #
  # @example Capture `$stderr`
  #
  #     output = capture(:stderr) { $stderr.puts "this is captured" }
  #
  # @param [Symbol] stream `:stdout` or `:stderr`
  # @yield The block to capture stdout/stderr for.
  # @return [String] The contents of $stdout or $stderr
  def capture(stream)
    begin
      stream = stream.to_s
      # rubocop:disable Security/Eval
      eval "$#{stream} = StringIO.new"
      yield
      result = eval("$#{stream}").string
      # rubocop:enable Security/Eval
    ensure
      # rubocop:disable Security/Eval
      eval("$#{stream} = #{stream.upcase}")
      # rubocop:enable Security/Eval
    end

    result
  end

  # Silences the output stream
  #
  # @example Silence `$stdout`
  #
  #     silence(:stdout) { $stdout.puts "hi" }
  #
  # @param [IO] stream The stream to use such as $stderr or $stdout
  # @return [nil]
  alias silence capture
end
