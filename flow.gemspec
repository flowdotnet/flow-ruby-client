# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "flow"
  s.version = "0.0.16"
  s.authors = ["Steve Benjamin"]
  s.email = ["steve@flow.net"]
  s.date = %q{2011-06-01}
  s.description = %q{Library for connecting to the Flow API}
  s.files = ["README.md", "Rakefile", 
	"examples/flow_type_examples.rb", 
	"flow.gemspec", "lib/flow.rb", 
	"lib/flow/flow_connection.rb", 
	"lib/flow/flow_types.rb", 
	"lib/flow/flow_base_types.rb", 
	"lib/flow/flow_field_types.rb", 
	"lib/flow/xmpp/client.rb"]
  s.homepage = %q{http://dev.flow.net}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{Flow connection library}

  s.add_dependency("json",[">= 1.5"])
  s.add_dependency("nokogiri",[">= 1.4"])
  s.add_dependency("blather",[">= 0.5.8"])
end
