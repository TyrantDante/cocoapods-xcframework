module Pod
  class Cmmd
    class << self
      def sh! command
        UI.puts command
        output = `#{command}`.lines.to_a
        if $?.exitstatus != 0
          Pod::ErrorUtil.error_report command,output
          Process.exit -1
        end
        output
      end

      def sh? command
        UI.puts command
        output = `#{command}`.lines.to_a
        if $?.exitstatus != 0
          Pod::ErrorUtil.error_report command,output
        end
        output
      end
    end
  end
end