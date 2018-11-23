require "forwardable"

module Jam
  class CLI
    class Command
      extend Forwardable
      include Jam::Colors

      def initialize(framework)
        @jam = framework
      end

      private

      def_delegators :jam,
                     :connect, :invoke_task, :load!,
                     :logger, :project, :settings, :tasks

      attr_reader :jam
    end
  end
end