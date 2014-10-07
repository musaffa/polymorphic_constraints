$:.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'polymorphic_constraints/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'polymorphic_constraints'
  s.version     = PolymorphicConstraints::VERSION
  s.authors     = ['Ahmad Musaffa']
  s.email       = ['musaffa_csemm@yahoo.com']
  s.homepage    = 'https://github.com/musaffa/polymorphic_constraints'
  s.summary     = 'Database agnostic referential integrity enforcer for Rails polymorphic associations using triggers.'
  s.description = 'Helps to maintain referential integrity for Rails polymorphic associations.'
  s.license     = 'MIT'

  s.files         = `git ls-files`.split($/)
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^spec/})
  s.require_paths  = ['lib']

  s.required_ruby_version = '>= 1.9.3'
  s.add_dependency 'rails'

  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'pg'
  s.add_development_dependency 'mysql2'
  s.add_development_dependency 'rspec-rails', '~> 3.0.2'
end
