module Pod
  module PodUtil
    include Config::Mixin

    def to_native_platform name
      case name
      when 'iphoneos' then 'ios'
      when 'macOS' then 'osx'
      when 'appletvos' then 'tvos'
      when 'watchos' then 'watchos'
      when 'ios' then 'ios'
      when 'macos' then 'osx'
      when 'tvos' then 'tvos'
      else
        name
      end
    end

    def muti_config_with_file(path)
      return nil if path.nil?
      path = Pathname.new(path)
      path = Pathname.new(Dir.pwd).join(path) unless path.absolute?
      @path = path.expand_path
      content = File.open(path, 'rb').read
      result = JSON.parse content
      if not result.is_a? Array
        UI.error "#{path} format not support"
        exit -1
      end
      result
    end

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

    def installation_root sandbox, spec, subspecs, sources,use_frameworks = true,use_modular_headers = true, enable_bitcode = false
        podfile = podfile_from_spec(
        @path,
        spec,
        subspecs,
        sources,
        use_frameworks,
        use_modular_headers
      )

      installer = Installer.new(sandbox, podfile)
      installer.repo_update = true
      installer.install!

      unless installer.nil? 
        installer.pods_project.targets.each do |target|
          target.build_configurations.each do |configuration| 
            if enable_bitcode && configuration.name == "Release"
              configuration.build_settings['ENABLE_BITCODE'] = 'YES'
              configuration.build_settings['BITCODE_GENERATION_MODE'] = 'bitcode'
            end
          end
          if target.name == spec.name
            target.build_configurations.each do |configuration|
              configuration.build_settings['CLANG_MODULES_AUTOLINK'] = 'NO'
            end
          end
        end
        installer.pods_project.save
      end
      installer
    end

    def installation_root_muti sandbox, configs, sources, use_frameworks = true, use_modular_headers = true, enable_bitcode = false
      podfile = podfile_from_muti_configs(
        configs,
        sources,
        use_frameworks,
        use_modular_headers
      )
      installer = Installer.new(sandbox, podfile)
      installer.repo_update = true
      installer.install!

      specs = configs.map do |cfg|
        cfg["name"]
      end
      unless installer.nil? 
        installer.pods_project.targets.each do |target|
          target.build_configurations.each do |configuration| 
            if enable_bitcode && configuration.name == "Release"
              configuration.build_settings['ENABLE_BITCODE'] = 'YES'
              configuration.build_settings['BITCODE_GENERATION_MODE'] = 'bitcode'
            end
          end
          if specs.include? target.name
            target.build_configurations.each do |configuration|
              configuration.build_settings['CLANG_MODULES_AUTOLINK'] = 'NO'
            end
          end
        end
        installer.pods_project.save
      end
      installer
    end

    def podfile_from_spec path, spec, subspecs, sources, use_frameworks = true, use_modular_headers=true
      options = Hash.new
      options[:podspec] = path.to_s
      options[:subspecs] = spec.subspecs.map do |sub|
        sub.base_name
      end
      options[:subspecs] = subspecs if subspecs
      # 非常奇怪，如果传一个空的数组过去就会出问题！！
      if options[:subspecs].length == 0
        options[:subspecs] = nil
      end
      static_library_enable = config.static_library_enable?
      Pod::Podfile.new do
        sources.each {|s| source s}
        spec.available_platforms.each do |plt|
          target "#{spec.name}-#{plt.name}" do
            platform(plt.name, spec.deployment_target(plt.name))
            pod(spec.name, options)
          end
        end

        install!('cocoapods',:integrate_targets => false,:deterministic_uuids => false)
        if static_library_enable
          use_frameworks! :linkage => :static if use_frameworks
        else
          use_frameworks! if use_frameworks
        end
        use_modular_headers! if use_modular_headers
      end
    end

    def podfile_from_muti_configs configs, sources, use_frameworks = true, use_modular_headers = true
      installation_root = config.installation_root.to_s
      static_library_enable = config.static_library_enable?
      Pod::Podfile.new do 
        sources.each {|s| source s}
        configs.each do |cfg|
          pod_spec_path = installation_root + "/#{cfg["name"]}/#{cfg["name"]}.podspec"
          pod_spec_json_path = pod_spec_path + ".json"
          (Pathname.glob(pod_spec_path) + Pathname.glob(pod_spec_json_path)).each do |real_path|
            spec = Pod::Specification.from_file real_path.to_s
            options = Hash.new 
            options[:podspec] = real_path.to_s
            if cfg["subspecs"]
              options[:subspecs] = cfg["subspecs"]
            else
              options[:subspecs] = spec.subspecs.map do |sub|
                sub.base_name
              end
            end
            # 非常奇怪，如果传一个空的数组过去就会出问题！！
            if options[:subspecs].length == 0
              options[:subspecs] = nil
            end
            spec.available_platforms.each do |plt|
              target "#{spec.name}-#{plt.name}" do 
                puts "#{plt.name} #{spec.name} #{options}"
                platform(plt.name, spec.deployment_target(plt.name))
                pod(spec.name, options)
              end
            end
          end
        end
        install!('cocoapods',
          :integrate_targets => false,
          :deterministic_uuids => false)

          if static_library_enable
            use_frameworks! :linkage => :static if use_frameworks
          else
            use_frameworks! if use_frameworks
          end
          use_modular_headers! if use_modular_headers
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

    def fix_header_file spec_hash, xcframework_path
      puts "Dir.glob(#{xcframework_path}/*/) : #{Dir.glob("#{xcframework_path}/*/")}"
      Dir.glob("#{xcframework_path}/*/").each do |file|
        ['ios','macos','tvos', 'watchos'].each do |prefix|
          last_path = file.split("/").last
          if last_path =~ /#{prefix}/ and not last_path =~ /simulator/
            platform = to_native_platform prefix
            if spec_hash[platform]
              spec_hash[platform]["public_header_files"] = "#{spec_hash[:vendored_frameworks]}/#{last_path}/*/Headers/*.h"
              spec_hash[platform]["source_files"] = "#{spec_hash[:vendored_frameworks]}/#{last_path}/*/Headers/*.h"
            else
              spec_hash[platform] = {
                "public_header_files" => "#{spec_hash[:vendored_frameworks]}/#{last_path}/*/Headers/*.h",
                "source_files" => "#{spec_hash[:vendored_frameworks]}/#{last_path}/*/Headers/*.h"
              }
            end
          end
        end
      end
      puts spec_hash.to_json
      spec_hash
    end
  end
end
