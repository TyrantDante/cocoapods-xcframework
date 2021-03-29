module Pod
  module PodUtil
    def spec_with_path(path)
      return if path.nil?
      path = Pathname.new(path)
      path = Pathname.new(Dir.pwd).join(path) unless path.absolute?
      return unless path.exist?
      @path = path.expand_path

      if @path.directory?
        raise @path + ': is a directory.'
        return
      end

      unless ['.podspec', '.json'].include? @path.extname
        raise @path + ': is not a podspec.'
        return
      end

      Specification.from_file(@path)
    end

    def spec_with_name(name)
      return if name.nil?

      set = Pod::Config.instance.sources_manager.search(Dependency.new(name))
      return nil if set.nil?

      set.specification.root
    end

    def build_static_sandbox
      Sandbox.new(config.sandbox_root)
    end

    def installation_root sandbox, spec, subspecs, sources,use_frameworks = true
        podfile = podfile_from_spec(
        @path,
        spec,
        # platform,
        subspecs,
        sources,
        use_frameworks
      )

      installer = Installer.new(sandbox, podfile)
      puts podfile.to_hash.to_json
      installer.install!

      unless installer.nil? 
        installer.pods_project.targets.each do |target|
          target.build_configurations.each do |configuration|
            configuration.build_settings['CLANG_MODULES_AUTOLINK'] = 'NO'
            configuration.build_settings['GCC_GENERATE_DEBUGGING_SYMBOLS'] = 'NO'
          end
        end
        installer.pods_project.save
      end
      installer
    end

    def podfile_from_spec path, spec, subspecs, sources, use_frameworks = true
        options = Hash.new
      options[:podspec] = path.to_s
      options[:subspecs] = subspecs if subspecs

      Pod::Podfile.new do
        sources.each {|s| source s}
        spec.available_platforms.each do |plt|
          target "#{spec.name}-#{plt.name}" do
            platform(plt.name, spec.deployment_target(plt.name))
            pod(spec.name, options)
          end
        end

        install!('cocoapods',
          :integrate_targets => false,
          :deterministic_uuids => false)
        
          use_frameworks! if use_frameworks
      end
    end

    def generic_new_podspec_hash spec
      spec_hash = spec.to_hash
      [
        "source_files",
        "resources",
        "resource_bundles",
        "prefix_header_contents",
        "prefix_header_file",
        "header_dir",
        "header_mappings_dir",
        "script_phase",
        "public_header_files",
        "private_header_files",
        "vendored_frameworks",
        "vendored_libraries",
        "exclude_files",
        "preserve_paths",
        "module_map",
        "subspec"
      ].each do |key|
        spec_hash.delete "#{key}"
      end
      spec_hash
    end
  end
end