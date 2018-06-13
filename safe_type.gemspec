Gem::Specification.new do |s|
  s.name        = 'safe_type'
  s.version     = '0.0.4'
  s.date        = '2018-06-13'
  s.summary     = "Type coercion & Type Enhancement"
  s.description = %q{ 
    Type coercion & Type Enhancement
  }
  s.authors     = ["Donald Dong"]
  s.email       = 'mail@ddong.me'
  s.homepage    = 'https://github.com/chanzuckerberg/safe_type'
  s.license     = 'MIT'
  s.files       = Dir.glob("lib/**/*.rb") + %w(README.md)

  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]

  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"
end
