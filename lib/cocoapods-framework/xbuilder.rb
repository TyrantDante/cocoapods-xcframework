require 'cocoapods-framework/xbuilder/xcode_xbuild'
require 'cocoapods-framework/xbuilder/xcodeproj_helper'
module Pod
  class XBuilder
    include XcodeXBuilder
    include XcodeProjHelper
    include PodUtil
    include Config::Mixin
    def initialize(installer, source_dir, sandbox_root, spec, configuration)
    # def initialize(platform, installer, source_dir, sandbox_root, spec, config)
        # @platform = platform
      @installer = installer
      @source_dir = source_dir
      @sandbox_root = sandbox_root
      @spec = spec
      @muti = @spec.is_a? Array
      @configs = @spec if @muti
      @spec = "muti" if @muti

      @configuration = configuration
      @outputs = Hash.new
    end

    def build
      UI.puts("Building framework #{@spec} with configuration #{@configuration}")
      UI.puts "Work dir is :#{@sandbox_root}"
      # defines = "GCC_PREPROCESSOR_DEFINITIONS='$(inherited) PodsDummy_Pods_#{@spec.name}=PodsDummy_PodPackage_#{@spec.name}'"
      defines = ""
      if @configuration == 'Debug'
        defines << 'GCC_GENERATE_DEBUGGING_SYMBOLS=YES ONLY_ACTIVE_ARCH=NO'
      else
        defines << "GCC_GENERATE_DEBUGGING_SYMBOLS=NO"
      end

      build_all_device defines

      collect_xc_frameworks

      collect_bundles
    end

    def collect_xc_frameworks
      if @muti
        collect_muti_xcframworks
      else
       collect_single_xcframeworks
      end
    end

    def collect_muti_xcframworks
      @outputs[:xcframework] = Hash.new
      @configs.each do |cfg|
        export_dir = "#{@sandbox_root}/export/**/#{cfg["name"]}.framework"
        frameworks = Pathname.glob(export_dir)
        @outputs[:xcframework][cfg["name"]] = create_xc_framework_by_frameworks frameworks, cfg["name"]
      end
    end

    def collect_single_xcframeworks
      export_dir = "#{@sandbox_root}/export/**/#{@spec.name}.framework"
      frameworks = Pathname.glob(export_dir)
      @outputs[:xcframework] = create_xc_framework_by_frameworks frameworks, @spec.name
    end

    def collect_bundles
      if @muti
        colelct_muti_bundles
      else
        collect_single_bundles
      end
    end

    def colelct_muti_bundles 
      @outputs[:bundle] = Hash.new
      @configs.each do |cfg|
        # "" 这个是用来代表mac os的 macos 没有后缀奇怪吧
        ["iphoneos","","appletvos","watchos"].each do |plat|
          export_dir = "#{@sandbox_root}/export/*-#{plat}/**/#{cfg["name"]}.bundle/**"
          Pathname.glob(export_dir).each do |bundle|
            if bundle.to_s.include? "#{@spec.name}.bundle/Info.plist"
              return
            end
            target_path = "#{@sandbox_root}/bundle/#{cfg["name"]}"
            @outputs[:bundle][cfg["name"]] = target_path
            native_platform = to_native_platform plat
            path = Pathname.new "#{target_path}/#{native_platform}"
            if not path.exist?
              path.mkpath
            end
            FileUtils.cp_r(Dir["#{bundle}"],"#{path}")
          end
        end
      end
    end

    def collect_single_bundles 
      # "" 这个是用来代表mac os的 macos 没有后缀奇怪吧
      ["iphoneos","","appletvos","watchos"].each do |plat|
        export_dir = "#{@sandbox_root}/export/*-#{plat}/**/#{@spec.name}.bundle/**"
        Pathname.glob(export_dir).each do |bundle|
          if bundle.to_s.include? "#{@spec.name}.bundle/Info.plist"
            return
          end
          @outputs[:bundle] = "#{@sandbox_root}/bundle"
          native_platform = to_native_platform plat
          path = Pathname.new "#{@sandbox_root}/bundle/#{native_platform}"
          if not path.exist?
            path.mkpath
          end
          FileUtils.cp_r(Dir["#{bundle}"],"#{path}")
        end
      end
    end

    def create_xc_framework_by_frameworks frameworks, spec_name
      command = 'xcodebuild -create-xcframework '
      frameworks.each do |framework|
        command << "-framework #{framework} "
      end
      command << "-output #{@sandbox_root}/#{spec_name}.xcframework 2>&1"
      output = `#{command}`.lines.to_a
      if $?.exitstatus != 0
        Pod::ErrorUtil.error_report command,output
        Process.exit -1
      end
      "#{@sandbox_root}/#{spec_name}.xcframework"
    end

    def build_all_device defines
      # build general first because simulator will exchange SDKROOT to simulat sdk
      build_general_device defines
      build_simulator_device defines
    end

    def build_general_device defines
      UI.puts("--- Building framework #{@spec} with general device")
      xcode_xbuild(
        defines,
        @configuration,
        @sandbox_root
      )
    end

    def build_simulator_device defines
      UI.puts("--- Building framework #{@spec} with simulator device")
      modify_xcode_project_sdk_to_simullator "#{@sandbox_root}/Pods.xcodeproj"
      xcode_xbuild(
        defines,
        @configuration,
        @sandbox_root
      )
    end

    def outputs target_dir
      if not File.exist? target_dir
        Pathname.new(target_dir).mkdir
      end
      outputs_xcframework target_dir
      outputs_bundle target_dir
      new_spec_hash = generic_new_podspec_hash @spec
      new_spec_hash[:vendored_frameworks] = "#{@spec.name}.xcframework"
      new_spec_hash = fix_header_file new_spec_hash, "#{target_dir}/#{@spec.name}.xcframework"
      find_bundles(target_dir).each do |plat, value| 
        if new_spec_hash[plat]
          new_spec_hash[plat]["resource_bundles"] = value
        else
          new_spec_hash[plat] = {
            "resource_bundles" => value
          }
        end
      end
      require 'json'
      spec_json = JSON.pretty_generate(new_spec_hash) << "\n"
      File.open("#{target_dir}/#{@spec.name}.podspec.json",'wb+') do |f|
        f.write(spec_json)
      end
      UI.puts "result export at :#{target_dir}"
      target_dir
    end
    
    def find_bundles target_dir
      bundle_root = "#{target_dir}/bundle/"
      pattern = "#{bundle_root}*"
      result = {}
      Pathname.glob(pattern).each do |bundle|
        bundle_relative_path = bundle.to_s.gsub(bundle_root, "")
        plat = bundle_relative_path
        result[plat] = {
          "#{@spec.name}" => "bundle/" + bundle_relative_path + "/*"
        }
      end
      result
    end

    def outputs_xcframework target_dir
      command = "cp -rp #{@outputs[:xcframework]} #{target_dir} 2>&1"
      output = `#{command}`.lines.to_a
      if $?.exitstatus != 0
        Pod::ErrorUtil.error_report command,output
        Process.exit -1
      end
    end

    def outputs_bundle target_dir
      if @outputs[:bundle]
        FileUtils.cp_r(Dir[@outputs[:bundle]],target_dir)
      end
    end

    def outputs_muti target_dir
      if not File.exist? target_dir
        Pathname.new(target_dir).mkdir
      end
      outputs_xcframework_muti target_dir
      outputs_bundle_muti target_dir
      generic_new_podspec_hash_muti target_dir
    end

    def generic_new_podspec_hash_muti target_dir
      work_dir = config.installation_root
      @configs.map do |cfg|
        podspec_path = "#{work_dir}/#{cfg["name"]}/#{cfg["name"]}.podspec"
        if not File.exist? podspec_path
          podspec_path = "#{podspec_path}.json"
        end
        podspec = Pod::Specification.from_file podspec_path
        new_spec_hash = generic_new_podspec_hash podspec
        new_spec_hash[:vendored_frameworks] = "#{podspec.name}.xcframework"
        new_spec_hash = fix_header_file new_spec_hash, "#{target_dir}/#{@spec.name}.xcframework"
        find_bundles("#{target_dir}/#{podspec.name}").each do |plat, value|
          if new_spec_hash[plat]
            new_spec_hash[plat]["resource_bundles"] = value
          else
            new_spec_hash[plat] = {
              "resource_bundles" => value
            }
          end
        end
        require 'json'
        spec_json = JSON.pretty_generate(new_spec_hash) << "\n"
        File.open("#{target_dir}/#{podspec.name}/#{podspec.name}.podspec.json",'wb+') do |f|
          f.write(spec_json)
        end
        UI.puts "result export at :#{target_dir}/#{podspec.name}"
        "#{target_dir}/#{podspec.name}"
      end
    end

    def outputs_xcframework_muti target_dir
      @outputs[:xcframework].each do |name, path|
        target_dir_path = "#{target_dir}/#{name}/"
        Pathname.new(target_dir_path).mkpath
        FileUtils.cp_r(path, target_dir_path)
      end
    end

    def outputs_bundle_muti target_dir
      @outputs[:bundle].each do |name, path|
        target_dir_path = "#{target_dir}/#{name}/bundle/"
        Pathname.new(target_dir_path).mkpath
        FileUtils.cp_r(path, target_dir_path)
      end
    end

  end
end
