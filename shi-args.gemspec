# frozen_string_literal: true

require_relative 'lib/shi/args/version'

Gem::Specification.new do |spec|
  spec.name = 'shi-args'
  spec.version = Shi::Args::VERSION
  spec.authors = ['Ivan Shikhalev']
  spec.email = ['shikhalev@gmail.com']

  spec.summary = 'Arguments parser for Jekyll custom tags'
  spec.homepage = 'https://github.com/shikhalev/shi-args'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 2.7.7'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/shikhalev/shi-args'
  spec.metadata['changelog_uri'] = 'https://github.com/shikhalev/shi-args/blob/main/CHANGELOG.md'
  spec.metadata['documentation_uri'] = 'https://rubydoc.info/gems/shi-args/'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  spec.add_dependency 'shi-tools', '~> 0.2.0'
  spec.add_dependency 'jekyll', '>= 4.0', '< 5.0'
  spec.add_dependency 'liquid', '~> 4.0'

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
