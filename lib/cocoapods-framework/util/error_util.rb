module Pod
  module ErrorUtil
    class << self
      def error_report(command, output)
        UI.puts "<<-EOF
        Build command failed: #{command}
        Output:
        #{output.map { |line| "    #{line}" }.join}
                  EOF"
      end
    end
  end
end