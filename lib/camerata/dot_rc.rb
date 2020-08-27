# frozen_string_literal: true
module Camerata
  class DotRc
    include Thor::Shell

    def initialize
      @file = find_file
      if @file
        say_status :load, @file
        load(@file)
      end
    end

    def find_file
      path = nil
      Pathname(Dir.pwd).ascend do |p|
        if File.directory?(p) && File.exists?(File.join(p, '.cameratarc'))
          path = File.join(p, '.cameratarc')
          break
        end
      end
      path
    end
  end
end
