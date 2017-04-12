$:.unshift(File.join(File.dirname(__FILE__), 'lib'))

spec = Gem::Specification.new do |s|
  s.name = 'fieldview'
  s.version = "0.0.0"
  s.required_ruby_version = '>= 1.9.3'
  s.summary = 'Ruby bindings for the FieldView API'
  s.description = ' FieldView is used make data-driven decisions to maximize your return on every acre.'
  s.author = 'Paul Susmarski'
  s.email = 'paul@susmarski.com'
  s.homepage = 'http://rubygems.org/gems/fielview'
  s.license = 'MIT'

  s.add_dependency('faraday', '~> 0.9')

  s.files = Dir['lib/**/*.rb']
  # s.files = `git ls-files`.split("\n")
  # s.test_files    = `git ls-files -- test/*`.split("\n")
  # s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']
end