# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "zyps/version"

Gem::Specification.new do |s|
  s.name        = "zyps"
  s.version     = Zyps::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Jay McGavren"]
  s.email       = ['jay@mcgavren.com']
  s.homepage    = "http://github.com/jaymcgavren/zyps"
  s.summary     = "A game library for Ruby"
  s.description = "Zyps are small creatures with minds of their own. You can create dozens of Zyps, then decide how each will act. (Will it run away from the others? Follow them? Eat them for lunch?) You can combine rules and actions to create very complex behaviors."

  s.rubyforge_project = "zyps"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  
  s.extra_rdoc_files = [
    "LICENSE",
    "README.md"
  ]
  
end
