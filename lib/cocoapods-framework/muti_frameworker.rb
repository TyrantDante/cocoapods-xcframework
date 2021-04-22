module Pod
  class MutiFrameworker
    include Pod::PodUtil
    include Pod::GitUtil
    include Pod::DirUtil
    include Config::Mixin
    def initialize(name, source, spec_sources, configuration, force, use_modular_headers)
      @name = name
      @source = source
      @spec_sources = spec_sources
      @configuration = configuration
      @force = force
      @use_modular_headers = use_modular_headers
    end

    def run
      configs = muti_config_with_file @name
      target_dir, work_dir = create_working_directory_by_spec "xcframeworks", @force
      prepare_git_with_configs configs, work_dir
      build_frameworks configs, work_dir, target_dir
    end

    def build_frameworks configs, work_dir, target_dir
        config.installation_root = Pathname.new work_dir
        config.sandbox_root = "#{work_dir}/Pods"
        sandbox = build_static_sandbox

        sandbox_installer = installation_root_muti(
          sandbox,
          configs,
          @spec_sources,
          @use_modular_headers
        )
        perform_build(
          sandbox,
          sandbox_installer,
          configs,
          target_dir
        )
    end

    def perform_build sandbox, installer, configs, target_dir
      sandbox_root = config.sandbox_root.to_s
      builder = Pod::XBuilder.new(
        installer,
        Dir.pwd,
        sandbox_root,
        configs,
        @configuration
      )
      builder.build
      builder.outputs_muti target_dir
    end


  end
end
