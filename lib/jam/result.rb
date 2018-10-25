module Jam
  class Result
    attr_reader :stdout, :stderr, :exit_status

    def initialize(stdout:, stderr:, exit_status:)
      @stdout = stdout
      @stderr = stderr
      @exit_status = exit_status
      freeze
    end

    def success?
      exit_status.zero?
    end

    def failure?
      !success?
    end
  end
end