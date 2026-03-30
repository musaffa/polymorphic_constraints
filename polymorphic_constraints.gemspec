$:.push File.expand_path('../lib', __FILE__)

require 'polymorphic_constraints/version'

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
  s.add_dependency 'rails', '>= 3.1'

  s.add_development_dependency 'bigdecimal', '~> 1.4.0'
  s.add_development_dependency 'rake', '~> 13.0'
  s.add_development_dependency 'minitest', '~> 5.15.0'
  s.add_development_dependency 'sqlite3', '~> 1.3.6'
  s.add_development_dependency 'pg', '~> 0.18'
  s.add_development_dependency 'mysql2', '~> 0.5'
  s.add_development_dependency 'rspec-rails', '~> 3.4.2'
end
