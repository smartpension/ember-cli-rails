module EmberCli
  class BuildMonitor
    def initialize(name, paths)
      @name = name
      @paths = paths
    end

    def check!
      if has_build_errors?
        raise_build_error!
      end

      true
    end

    def reset
      if error_file_exists?
        error_file.delete
      end
    end

    def wait!
      loop do
        check!
        break if complete?
        sleep 0.1
      end
    end

    private

    attr_reader :name, :paths

    def complete?
      !paths.lockfile.exist?
    end

    def error_file_exists?
      error_file.exist? && error_file.size?
    end

    def build_errors
      error_lines.
        reject { |line| is_blank_or_backtrace?(line) }.
        reject { |line| is_deprecation_warning?(line) }.
        reject { |line| line =~ /building/i }.
        reject { |line| line =~ /warning/i }
    end

    def has_build_errors?
      build_errors.any?
    end

    def is_blank_or_backtrace?(line)
      line =~ /(^\s*$|^\s{4}at .+$)/
    end

    def is_deprecation_warning?(line)
      line =~ /^(\e[^\s]+)?DEPRECATION:/
    end

    def error_lines
      if error_file_exists?
        error_file.readlines
      else
        [""]
      end
    end

    def error_file
      paths.build_error_file
    end

    def raise_build_error!
      error = BuildError.new("#{name.inspect} has failed to build:")

      puts build_errors

      fail error
    end
  end
end
