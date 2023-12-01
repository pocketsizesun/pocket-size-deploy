# frozen_string_literal: true

require_relative "lib/pocket_size/deploy/version"

Gem::Specification.new do |spec|
  spec.name = "pocket-size-deploy"
  spec.version = PocketSize::Deploy::VERSION
  spec.authors = ["Julien D."]
  spec.email = ["julien@pocketsizesun.com"]

  spec.summary = "Pocket Size Deploy"
  spec.description = "Pocket Size Deploy"
  spec.homepage = "https://github.com/pocketsizesun/pocket-size-deploy"
  spec.required_ruby_version = ">= 2.6.0"

  # spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/pocketsizesun/pocket-size-deploy"
  spec.metadata["changelog_uri"] = "https://github.com/pocketsizesun/pocket-size-deploy"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "activemodel", "> 6.0"
  spec.add_dependency "base32", "~> 0.3"
  spec.add_dependency 'aws-sdk-elasticloadbalancingv2', '> 1'
  spec.add_dependency 'aws-sdk-ssm', '> 1'
  spec.add_dependency 'aws-sdk-ecr', '> 1'
  spec.add_dependency 'highline', '~> 2.0'

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
