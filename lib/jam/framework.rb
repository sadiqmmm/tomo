require "forwardable"

module Jam
  class Framework
    autoload :ChildProcess, "jam/framework/child_process"
    autoload :Current, "jam/framework/current"
    autoload :PluginsRegistry, "jam/framework/plugins_registry"
    autoload :ProjectLoader, "jam/framework/project_loader"
    autoload :SettingsRegistry, "jam/framework/settings_registry"
    autoload :SSHConnection, "jam/framework/ssh_connection"
    autoload :TasksRegistry, "jam/framework/tasks_registry"

    extend Forwardable
    def_delegators :tasks_registry, :tasks

    attr_reader :helper_modules, :logger, :paths, :settings

    def initialize
      @current = Current.new
      @helper_modules = [].freeze
      @logger = Logger.new
      @paths = Paths.new(@settings)
      @settings = {}.freeze
    end

    def load!(settings: {}, plugins: ["core"])
      plugins.each { |plug| plugins_registry.load_plugin_by_name(plug) }
      settings_registry.assign(settings)
      @helper_modules = plugins_registry.helper_modules.freeze
      @settings = settings_registry.to_hash.freeze
      @paths = Paths.new(@settings)
      freeze
    end

    def load_project!(environment: nil, settings: {})
      project_loader.load_project(environment).tap do
        load!(settings: settings)
      end
    end

    def connect(host)
      conn = SSHConnection.new(host, logger)
      remote = Remote.new(conn, self)
      current.set(remote: remote) do
        yield(remote)
      end
    ensure
      conn&.close
    end

    def invoke_task(task)
      logger.task_start(task)
      tasks_registry.invoke_task(task)
    end

    def remote
      current[:remote]
    end

    private

    attr_reader :current

    def plugins_registry
      @plugins_registry ||= begin
        PluginsRegistry.new(
          settings_registry: settings_registry,
          tasks_registry: tasks_registry
        )
      end
    end

    def project_loader
      @project_loader ||= begin
        ProjectLoader.new(
          settings_registry: settings_registry,
          plugins_registry: plugins_registry,
          tasks_registry: tasks_registry
        )
      end
    end

    def settings_registry
      @settings_registry ||= SettingsRegistry.new
    end

    def tasks_registry
      @tasks_registry ||= TasksRegistry.new(self)
    end
  end
end
