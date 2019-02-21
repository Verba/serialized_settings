Gem::Specification.new do |s|
  s.name        = 'serialized_settings'
  s.version     = '2.0.0'
  s.date        = '2014-11-11'
  s.summary     = "Handles serializing and deserializing settings on an ActiveRecord model, with default settings and dotted path key syntax (from.hash.to.hash => value)."
  s.authors     = [ "Verba "]
  s.email       = [ "tech@verba.io" ]
  s.files       = Dir["lib/**/*"]
  s.test_files  = Dir["spec/**/*"]

  s.add_dependency "activerecord"
  s.add_dependency "activesupport"

  s.add_development_dependency "bump"
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"
  s.add_development_dependency "sqlite3", "~> 1.3.6"
end
