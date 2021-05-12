# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cocoapods-framework/gem_version.rb'

Gem::Specification.new do |spec|
  spec.name          = 'cocoapods-xcframework'
  spec.version       = CocoapodsFramework::VERSION
  spec.authors       = ['戴易超']
  spec.email         = ['daiyichao@corp.netease.com']
  spec.description   = %q{把podspec打包成xcframework的小工具。packager pod to a xcframework}
  spec.summary       = %q{把podspec打包成xcframework的小工具。packager pod to a xcframework}
  spec.homepage      = 'https://github.com/TyrantDante/cocoapods-framework'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']
  spec.add_dependency "cocoapods", '>= 1.10.0', '< 2.0'

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
end
