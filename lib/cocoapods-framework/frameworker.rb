module Pod
  class Frameworker
    include PodUtil
    include DirUtil
    include Config::Mixin
    def initialize(name, source, spec_sources, subspecs, configuration, force, use_modular_headers, enable_bitcode)
      @name = name
      @source = source
      @spec_sources = spec_sources
      @subspecs = subspecs
      @configuration = configuration
      @force = force
      @use_modular_headers = use_modular_headers
      @enable_bitcode = enable_bitcode
    end

    def run
      spec = spec_with_path @name
      @is_spec_from_path = true if spec
      spec ||= spec_with_name @name

      target_dir, work_dir = create_working_directory_by_spec spec, @force
      build_framework spec, work_dir, target_dir
    end

    def build_framework spec, work_dir, target_dir
      build_in_sandbox(work_dir, spec, target_dir)
    end

    def build_in_sandbox work_dir, spec, target_dir
      config.installation_root  = Pathname.new work_dir
      config.sandbox_root       = "#{work_dir}/Pods"
      sandbox = build_static_sandbox

      sandbox_installer = installation_root(
        sandbox,
        spec,
        @subspecs,
        @spec_sources,
        true,
        @use_modular_headers,
        @enable_bitcode
      )

      perform_build(
        sandbox,
        sandbox_installer,
        spec,
        target_dir
      )
    end

    # def perform_build platform, sandbox, installer, spec
    def perform_build sandbox, installer, spec, target_dir
      sandbox_root = config.sandbox_root.to_s
      builder = Pod::XBuilder.new(
        installer,
        Dir.pwd,
        sandbox_root,
        spec,
        @configuration
      )
      builder.build
      builder.outputs target_dir
      target_dir
    end
  end
end