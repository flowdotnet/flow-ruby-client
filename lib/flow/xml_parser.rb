require 'nokogiri'
module Flow
  module XmlParser
    
    ARRAY_TYPES={"sortedSet"=>nil,"constraints"=>nil}
    TYPE_CONVERTERS={
      "date"=>  Proc.new{ |i| i.to_i} ,
      "boolean"=>Proc.new { |i| i=='true'? true: false }    
    }
    
    def Parser
      
      def self.from_raw contents
        Parser.new NokogiriXML(contents)
      end

      def initialize(doc)
        @doc=doc
        @value=add_to_m({}, doc.root)
      end

      attr_reader :doc,:value

      :private
      
      def convert(type, elem)
        TYPE_CONVERTERS.has_key?(type) ? TYPE_CONVERTERS[type].call(elem) : elem
      end
      
      def is_text_node(elem)
        elem.children.size==1 and elem.children[0].name == "text" 
      end
      
      def is_array_node(elem)
        ARRAY_TYPES.has_key?(elem.attr("type"))
      end
      
      def skip_node(elem)
        elem.name=="text" and elem.attributes.size()==0
      end
      
      def att_to_m(attributes)
        attributes.inject({}){ |m,att| m[att.name]=att.value; m}
      end
      
      def to_node(attributes, v)
        type=attributes["type"]
        return convert(type,v) unless type.nil?
        v 
      end
      
      def add_to_m(m,elem)
        v=nil
        if skip_node(elem)
          return
        elsif is_text_node(elem)
          contents=elem.children[0].text.strip()
          v = contents unless contents.size()==0
        elsif is_array_node(elem)
          v=[]
          elem.children.each do |child|
            m_inner={}
            add_to_m(m_inner, child)
            v.push(m_inner.values[0]) unless m_inner.size()==0
          end
        else 
          v={}
          elem.children.each do |child|
            add_to_m(v,child)
          end
        end
        n=to_node(att_to_m(elem.attribute_nodes), v) unless v.nil?
        m[elem.name]=n unless n.nil?
      end
    end
  end
end
