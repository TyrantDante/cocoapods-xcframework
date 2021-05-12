module Pod
  module ErrorUtil
    class << self
      def error_report(command, output)
        # UI.puts "<<-EOF
        # Build command failed: #{command}
        # Output:
        # #{output.map { |line| "    #{line}" }.join}
        #           EOF"
        find_error output
      end

      def find_error(output)
        output..each do |line|
          if line.include? "Ld /Library/Caches/com.netease.ios.martin.package/PHFDelegateChain/build/Pods.build/Release-iphoneos/PHFDelegateChain.build/Objects-normal/armv7/Binary/PHFDelegateChain"
            puts line
          end
        end
      end

    end
  end
end