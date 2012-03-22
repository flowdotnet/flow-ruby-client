#!/usr/bin/env ruby

#require 'rubygems'
require 'blather'
require 'digest/sha1' 
require 'logger' 
require 'nokogiri'

module Flow
  module XMPP
    
    class Client
      FLOW_XMPP_SERVER = 'xmpp.flow.net'
      FLOW_APPNAME = 'baseapp'

      def initialize(flow_alias, &callback)
        @flow_alias=flow_alias
        @credentials=::Flow.credentials
        @pass=Digest::SHA1.hexdigest("#{@credentials.key}#{@credentials.secret}#{@credentials.id}")
        @jid="#{FLOW_APPNAME}##{@flow_alias}@#{FLOW_XMPP_SERVER}"
        @subscriptions=[]
        @callback=callback
      end
      
      def start
        Blather::Stream::Client.start(self, @jid, @pass)
      end

      def on_drop_receive drop
        @callback.call drop
      end

      def subscribe id
        unless subscriptions.include? id
          subscriptions.push id
          subscribe_to if @stream
        end
      end

      def post_init(stream, jid = nil)
        @stream = stream
        @jid=jid
        @pong="<iq type='set' to='pubsub.#{FLOW_XMPP_SERVER}' from='#{@jid}'><query xmlns='flow:pubsub'><pong/></query></iq>"
        @stream.send_data Blather::Stanza::Presence::Status.new
        @stream.send_data "<presence to='pubsub.#{FLOW_XMPP_SERVER}' from='#{@jid}'/>"
        subscriptions.each { |i| subscribe_to i }
      end

      def receive_data(stanza)
        puts "GET STANZA #{stanza}"
        if stanza.name == 'iq'
          if is_ping stanza
            @stream.send_data @pong
          elsif is_drop stanza
            on_drop_receive extract_drop(stanza)
          end
        end
      end

      def unbind
        print "unbind\n"
      end
      
      def extract_drop(node)
        n=node.xpath("//x:drop", "x"=>"flow:pubsub")
        ::Flow::Drop.from_xml_doc(n[0]) if n[0]
      end
      
      def unsubscribe id
          @stream.send_data "<iq type='set' from='#{@jid}' to='pubsub.#{FLOW_XMPP_SERVER}> <query xmlns='flow:pubsub'><unsubscribe flow='#{id}'/></query></iq>"
      end

      def self.set_debug(debug)
          Blather.logger.level=debug ? Logger::DEBUG : Logger::WARN
      end

      attr_reader :flow_alias, :credentials, :jid, :subscriptions
      private
      
      def subscribe_to id
        @stream.send_data "<iq type='set' from='#{@jid}' to='pubsub.#{FLOW_XMPP_SERVER}'><query xmlns='flow:pubsub'><subscribe flow='#{id}'/></query></iq>"
      end

      def is_drop(node)
        node.xpath("//x:drop", "x"=>"flow:pubsub").size > 0
      end
      
      def is_ping(node)
        node.xpath("//x:ping", "x"=>"flow:pubsub").size()>0
      end
      
    end
  end
end
