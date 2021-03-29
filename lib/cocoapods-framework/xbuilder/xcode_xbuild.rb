module Pod
  class XBuilder
    module XcodeXBuilder
      def xcode_xbuild(defines, configuration, work_dir, build_dir = 'export')
        if defined?(Pod::DONT_CODESIGN)
          args = "#{args} CODE_SIGN_IDENTITY=\"\" CODE_SIGNING_REQUIRED=NO"
        end
        pwd = Pathname.pwd
        Dir.chdir work_dir
        command = "xcodebuild #{defines} BUILD_DIR=#{build_dir} BUILD_LIBRARY_FOR_DISTRIBUTION=YES clean build -configuration #{configuration} -alltargets 2>&1"
        output = `#{command}`.lines.to_s
        Dir.chdir pwd
        if $?.exitstatus != 0
          UI.puts output.join("")
          Process.exit -1
        end
      end
    end
  end
end