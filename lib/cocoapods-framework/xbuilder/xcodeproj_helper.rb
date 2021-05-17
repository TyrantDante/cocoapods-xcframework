require 'xcodeproj'
module Pod
  class XBuilder
    module XcodeProjHelper
      include PodUtil
      def modify_xcode_project_sdk_to_simullator path
        sdks = xcode_sdks
        project = Xcodeproj::Project.open path

        project.targets.each do |target|
          simulator_sdk = to_native_simulator_platform target.sdk
          if not simulator_sdk.nil?
            canonicalName = sdks[simulator_sdk]["canonicalName"]
            target.build_configurations.each do |configuration|
              configuration.build_settings["SDKROOT"] = canonicalName
            end
          end
        end
        project.save
      end

      private
      def xcode_sdks
        return @x_sdks if @x_sdks
        outputs = `xcodebuild -showsdks -json`
        sdks = JSON.parse outputs
        @x_sdks = {}
        sdks.each do |sdk|
          @x_sdks[sdk["platform"]] = sdk
        end
        @x_sdks
      end

      def to_native_simulator_platform name
        case name
        when 'iphoneos' then 'iphonesimulator'
        when 'macOS' then nil
        when 'appletvos' then 'appletvsimulator'
        when 'watchos' then 'watchsimulator'
        else
          name
        end
      end
    end
  end
end