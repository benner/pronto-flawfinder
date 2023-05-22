# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)

require 'pronto/flawfinder/version'

Gem::Specification.new do |s|
  s.name = 'pronto-flawfinder'
  s.version = Pronto::FlawfinderVersion::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ['Nerijus Bendziunas']
  s.email = 'nerijus.bendziunas@gmail.com'
  s.homepage = 'https://github.com/benner/pronto-flawfinder'
  s.summary = <<-SUMMARY
    Pronto runner for flawfinder.
  SUMMARY

  s.licenses = ['Apache-2.0']
  s.required_ruby_version = '>= 3.1.0'

  s.files = Dir.glob('{lib}/**/*') + %w[LICENSE README.md]
  s.extra_rdoc_files = ['LICENSE', 'README.md']
  s.require_paths = ['lib']
  s.requirements << 'flawfinder (in PATH)'

  s.add_dependency('pronto', '< 12.0.0')
  s.metadata['rubygems_mfa_required'] = 'true'
end
