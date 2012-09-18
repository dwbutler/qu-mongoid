# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "qu-mongoid/version"

Gem::Specification.new do |s|
  s.name        = "qu-mongoid"
  s.version     = Qu::Mongoid::VERSION
  s.authors     = ["David Butler"]
  s.email       = ["dwbutler@ucla.edu"]
  s.homepage    = "http://github.com/dwbutler/qu-mongoid"
  s.summary     = "Mongoid backend for Qu"
  s.description = "Mongoid backend for the Ruby queuing library Qu"

  s.files         = `git ls-files`.split("\n")
  s.require_paths = ["lib"]

  s.add_dependency 'mongoid', '~> 3.0'
  s.add_dependency 'qu'
end
