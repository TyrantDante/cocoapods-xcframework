module Pod
  class Command
    # This is an example of a cocoapods plugin adding a top-level subcommand
    # to the 'pod' command.
    #
    # You can also create subcommands of existing or new commands. Say you
    # wanted to add a subcommand to `list` to show newly deprecated pods,
    # (e.g. `pod list deprecated`), there are a few things that would need
    # to change.
    #
    # - move this file to `lib/pod/command/list/deprecated.rb` and update
    #   the class to exist in the the Pod::Command::List namespace
    # - change this class to extend from `List` instead of `Command`. This
    #   tells the plugin system that it is a subcommand of `list`.
    # - edit `lib/cocoapods_plugins.rb` to require this file
    #
    # @todo Create a PR to add your plugin to CocoaPods/cocoapods.org
    #       in the `plugins.json` file, once your plugin is released.
    #
    class Framework < Command
      self.summary = 'Package a podspec into a xcframework.'
      self.arguments = [
        CLAide::Argument.new('NAME', true),
        CLAide::Argument.new('SOURCE', false)
      ]
      include Config::Mixin

      def self.options 
        [
          ['--no-force',     'Overwrite existing files.'],
          ['--configuration', 'Build the specified configuration (e.g. Debug). Defaults to Release'],
          ['--spec-sources=private,https://github.com/CocoaPods/Specs.git', 'The sources to pull dependent pods from (defaults to https://github.com/CocoaPods/Specs.git)'],
          ['--subspecs', 'Only include the given subspecs'],
          ['--use-modular-headers', 'pakcage uses modular headers during packaging'],
          ['--no-static-library', 'package not use static library'],
          ['--enable-bitcode', 'package enable bitcode']
        ].concat super
      end

      def initialize(argv)
        @name = argv.shift_argument
        @source = argv.shift_argument
        @spec_sources = argv.option('spec-sources', 'https://github.com/CocoaPods/Specs.git').split(',')
        subspecs = argv.option('subspecs')
        @subspecs = subspecs.split(',') unless subspecs.nil?
        @configuration = argv.option('configuration', 'Release')
        @use_modular_headers = argv.option('use-modular-headers', true)
        @force = argv.flag?('force', true)
        @use_static_library = argv.flag?('static-library',true)
        @enable_bitcode = argv.flag?('enable-bitcode',false)
        config.static_library_enable = @use_static_library
        super
      end

      def validate!
        super
        help! 'A Pod name is required.' unless @name
      end

      def run
        frameworker = Frameworker.new(@name, @source, @spec_sources, @subspecs, @configuration, @force, @use_modular_headers, @enable_bitcode)
        frameworker.run
      end
    end
  end
end
