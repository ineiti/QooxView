# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'qooxview'
  spec.version = '1.9.1312'
  spec.authors       = ['Linus Gasser']
  spec.email = 'ineiti.blue'
  spec.summary       = %q{Implements a ruby-backend for QooxDoo.org}
  spec.description   = %q{This is a very simple framework to create small
  frontends in a webserver}
  spec.homepage      = 'https://github.com/ineiti/qooxview'
  spec.license = 'GPL-3.0'

  spec.files         = `if [ -d '.git' ]; then git ls-files -z; fi`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'helper_classes', '0.4.0'
  spec.add_dependency 'activemodel', '5.1.0'
  spec.add_dependency 'activerecord', '5.1.0'
  spec.add_dependency 'sqlite3', '1.3.10'
  spec.add_dependency 'activesupport', '5.1.0'
  spec.add_dependency 'arel', '8.0'
  spec.add_dependency 'chunky_png', '1.3.4'
  spec.add_dependency 'gettext', '3.0.0'
  spec.add_dependency 'i18n', '0.7.0'
  spec.add_dependency 'iconv', '1.0.3'
  spec.add_dependency 'json', '2.1.0'
  spec.add_dependency 'locale', '2.0.8'
  spec.add_dependency 'multi_json', '1.0.3'
  spec.add_dependency 'net-ldap', '0.16'
  spec.add_dependency 'iniparse', '1.4.0'
  spec.add_dependency 'rqrcode', '0.4.2'
  spec.add_dependency 'rubyzip', '1.1.7'
  spec.add_dependency 'serialport', '1.3.1'
  spec.add_dependency 'text', '1.2.3'
  spec.add_dependency 'docsplit', '0.7.6'
  spec.add_dependency 'rqrcode-with-patches', '0.5.4'
  spec.add_dependency 'test-unit', '3.2.3'
  # spec.add_development_dependency 'perftools.rb', '2.0.1'
  spec.add_development_dependency 'bundler', '~> 1.14'
  spec.add_development_dependency 'rake', '~> 10.0'
end

