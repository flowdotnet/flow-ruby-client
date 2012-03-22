$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

module Flow
  VERSION = '0.0.16'
end

require 'flow/flow_connection'
require 'flow/flow_field_types'
require 'flow/flow_base_types'
require 'flow/flow_types'
require 'flow/xmpp/client'



#require 'uri'

=begin rdoc
Connections to flow api.

== Useage

== Searches 
The api supports a few different types of searches

* <tt>search</tt> - A general keyword search over the entire domain. May return different types of objects.
* <tt>query</tt> - Keyword search for a specific type of obejct.
* <tt>criteria</tt> - Search by matching values in an input map.
* <tt>filter</tt> - Search drops within a specific bycket by a provided parseable filter string (see below for supported syntax).

=end
