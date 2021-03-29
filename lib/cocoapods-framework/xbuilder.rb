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
      @configuration = configuration
      @outputs = nil
    end

    def build
      UI.puts("Building framework #{@spec} with configuration #{@configuration}")
      UI.puts "Work dir is :#{@sandbox_root}"
      defines = "GCC_PREPROCESSOR_DEFINITIONS='$(inherited) PodsDummy_Pods_#{@spec.name}=PodsDummy_PodPackage_#{@spec.name}'"
      # defines << ' ' << @spec.consumer(@platform).compiler_flags.join(' ')

      if @configuration == 'Debug'
        defines << 'GCC_GENERATE_DEBUGGING_SYMBOLS=YES ONLY_ACTIVE_ARCH=NO'
      end

      build_all_device defines

      collect_xc_frameworks
    end

    def collect_xc_frameworks
      export_dir = "#{@sandbox_root}/export/**/#{@spec.name}.framework"
      frameworks = Pathname.glob(export_dir)
      @outputs = create_xc_framework_by_frameworks frameworks
    end

    def create_xc_framework_by_frameworks frameworks
      command = 'xcodebuild -create-xcframework '
      frameworks.each do |framework|
        command << "-framework #{framework} "
      end
      command << "-output #{@sandbox_root}/#{@spec.name}.xcframework 2>&1"
      output = `#{command}`
      if $?.exitstatus != 0
        Pod::ErrorUtil.error_report command,output
        Process.exit -1
      end
      "#{@sandbox_root}/#{@spec.name}.xcframework"
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
      new_spec_hash = generic_new_podspec_hash @spec
      new_spec_hash[:vendored_frameworks] = "#{@spec.name}.xcframework"
      require 'json'
      spec_json = JSON.pretty_generate(new_spec_hash) << "\n"
      File.open("#{target_dir}/#{@spec.name}.podspec.json",'wb+') do |f|
        f.write(spec_json)
      end
      UI.puts "result export at :#{target_dir}"
      target_dir
    end

    def outputs_xcframework target_dir
      command = "cp -rp #{@outputs} #{target_dir} 2>&1"
      output = `#{command}`
      if $?.exitstatus != 0
        Pod::ErrorUtil.error_report command,output
        Process.exit -1
      end
    end
  end
end