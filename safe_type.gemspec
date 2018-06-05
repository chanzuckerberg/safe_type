Gem::Specification.new do |s|
  s.name        = 'safe_type'
  s.version     = '0.0.2'
  s.date        = '2018-06-04'
  s.summary     = "Type coercion and enhancement"
  s.description = %q{ 
    Type coercion and enhancement
  }
  s.authors     = ["Donald Dong"]
  s.email       = 'mail@ddong.me'
  s.homepage    = 'https://github.com/chanzuckerberg/safe_type'
  s.license     = 'MIT'
  s.files       = Dir.glob("lib/**/*.rb") + %w(README.md)

  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
end
