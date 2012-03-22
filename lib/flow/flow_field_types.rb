module Flow
  module Base
    #internally designed fields for constraining input
    class F_Field
      
      @flow_type_name=nil

      def self.accepts?(value)
        true
      end
      
      def self.extract_if_valid(value)
        v=self.extract_hinted(value)
        raise ArgumentError, "#{self} doesn't accept the value '#{v.inspect}'" if !self.accepts?(v)
        v
      end
      
      def self.type_name
        @flow_type_name
      end

      def self.hint(v)
        hints = ::Flow.connection.hints unless ::Flow.connection.nil?
        if hints
          return {"type"=>@flow_type_name, "value"=>v} 
        end
        v
      end
      
      def self.extract_hinted(v)
        if v.is_a? Hash 
          if (v.size==2) and (v.has_key? "value")
            return extract_hinted(v["value"])
          else
            return v.inject({}) { |map,elem| map[elem[0]]=extract_hinted(elem[1]); map }
          end
        end
        v
      end
   end
    
    #Simple fields
    class F_Boolean < F_Field
      @flow_type_name="boolean"

      def self.accepts?(value)
        value==true or value==false
      end
    end
  
    class F_Date < F_Field
      @flow_type_name="date"

      #Dates are input as milliseconds from 1970
      def self.accepts?(value)
        value.is_a? Integer or value.to_s =~ /^[0-9]+$/
      end
    end

    class F_Integer < F_Field
      @flow_type_name="integer"

      def self.accepts?(value)
        value.is_a? Integer or value.to_s =~ /^[0-9]+$/
      end
    end
 
   class F_String < F_Field
      @flow_type_name="string"

      def self.accepts?(value)
        value.is_a? String
      end
    end

    class F_Path < F_Field
      @flow_type_name="path"

      def self.accepts?(value)
        value.is_a? String and value.start_with? '/'
      end
    end

    class F_ElemsMap < F_Field
      @flow_type_name="map"

      def self.accepts?(value)
        value.is_a? Hash
      end
      
      #Elems are always returned hinted
      def self.extract_if_valid(v)
        raise ArgumentError, "#{self} doesn't accept the value '#{v.inspect}'" if !self.accepts?(v)
        return (v.has_key? "value") ? v["value"] : v
      end
    end

    class F_Email < F_Field
      @flow_type_name="email"
      #This isn't anywhere near complete self.checking, which is too complicated to be worth it,
      #but if this passes you probably intended it to be an ameil.
      def self.accepts?(value)
        value =~ /^.+@[^\.]+\..*$/
      end
    end
    
    class F_ObjectId < F_Field
      @flow_type_name="id"

      #accepts any string made up of exactly 24 standard hex chars
      #(case-insensitive)
      def self.accepts?(value)
        value =~ /^[0-9a-fA-F]{24}$/
      end
    end
    
    class F_Url < F_Field
      @flow_type_name="url"

      def self.accepts?(value)
        value =~ /^#{URI.regexp}$/
      end
    end
    
    class F_Collection < F_Field
      @flow_type_name="list"
      @collection_type=nil

      def self.accepts?(v)
        v.is_a? Array and ( @collection_type.nil? or v.all? { |i| @collection_type.accepts? i} )
      end  
      
      def self.of(name,collection_type)
        klazz = Class.new F_Collection do
          @collection_type=collection_type
        end
        Object.const_set name, klazz
      end

    end
    
    # --- composite fields ---
    class F_Map < F_Field
      @flow_type_name="map"
      @map={}
      
      def self.accepts?(v)
        v.is_a?Hash and (@map.nil? or self.map_match(v,@map))
      end  

      
      def self.of(name, values)
        klazz=Class.new F_Map do
          
          def self.inject(m)
            return nil if m.nil?
            m.inject({}) { |k,(m,n)| k[m]=inject(n); k }
          end

          @map=self.inject(values)
          @flow_type_name=name
        end
        Object.const_set name.capitalize, klazz
      end
      
      def self.map
        @map
      end
      #input map follows the structure of the reference format.
      #extra keys that don't exist in the reference format throw
      #an argument error
      #
      #missing keys is allowed
      protected
      def self.map_match(m,ref)
        m.each do |k,v|
          raise ArgumentError,"Bad field #{k.inspect} on #{self}" if !ref.has_key?(k) 
          inner_ref=ref[k]
          if !inner_ref.nil?
            map_match(v, inner_ref)
          end
        end
      end
      
      def self.array_match(m,key,matcher)
        if (m.nil? or !m.has_key?(key)) 
          return true
        end
        m[key].each { |i| matcher.accepts? i}
      end
    end
    
    class F_Flags < F_Field
    end
    
    class F_Transform < F_Map
      @map={"function"=>nil,"copyAll"=>nil, "joins"=>nil}
      @join_map={"path"=>nil, "filter"=>nil, "copyAll"=>nil,"sort"=>nil}
      @flow_type_name="transform"

      def self.accepts?(v)
        self.map_match(v,@map) and self.accepts_joins?(v)
      end
      
      def self.accepts_joins?(v)
        if v.has_key? "joins"
          v["joins"].each { |i| map_match(i, @join_map)}
        end
      end
    end
      
    class F_Actions < F_Map
      @flow_type_name="map"
      @map={"delete"=>nil,"dropRead"=>nil,"dropDelete"=>nil,"read"=>nil,"dropWrite"=>nil,"write"=>nil}
    end

    class F_Creator < F_Map
      @flow_type_name="map"
      @map={"fname"=>nil, "lname"=>nil, "alias"=>nil,"application"=>nil}
    end
    
    class F_Permissions < F_Map
      @flow_type_name="permissions"
      @map={"read"=>{"value"=>nil, "access"=>nil, "type"=>nil},"write"=>{"value"=>nil, "access"=>nil, "type"=>nil},"delete"=>{"value"=>nil, "access"=>nil, "type"=>nil}}
    end
  
    class F_ApplicationTemplate < F_Map
      @flow_type_name="applicationTemplate"
      @flow_template = F_Map.of("flowTemplate",
                                {"name"=>nil,
                                  "displayName"=>nil, 
                                  "dropElements"=>nil, 
                                  "description"=>nil, 
                                  "permissions"=>{"read"=>nil,"write"=>nil, "delete"=>nil},
                                  "dropPermissions"=>{"read"=>nil,"write"=>nil,"delete"=>nil}
                                })
      @flow_template.class_eval do
        @drop_template = F_Map.of("dropTemplate",["name", "description","class","required"])
        def self.accepts?(v)
          super and self.array_match(v,"dropElements", @drop_template)
        end
      end

      @track_template = F_Map.of("trackTemplate",["from","to","filter","transformFunction"])
      @track_template.class_eval do
        def self.accepts?(v)
          super and  F_Transform.accepts?(v["transformFunction"]) if v.has_key? "transformFunction"
        end
      end

      def self.accepts?(v)
        self.array_match(v, "userFlows", @flow_template) and self.array_match(v,"userTracks", @track_template)
      end

    end

    class F_DropId < F_Field;end
    
    class F_Location < F_Field;end
    
    class F_Flags < F_Field;end
  
    class F_Constraints < F_Field;end

    class F_Ratings < F_Field;end
    
  end
end
module Flow
  module Base
    #internally designed fields for constraining input
    class F_Field
      
      @flow_type_name=nil

      def self.accepts?(value)
        true
      end
      
      def self.type_name
        @flow_type_name
      end

      def self.hint(v)
        hints = ::Flow.connection.hints unless ::Flow.connection.nil?
        if hints
          return {"type"=>@flow_type_name, "value"=>v} 
        end
        v
      end
      
   end
    
    #Simple fields
    class F_Boolean < F_Field
      @flow_type_name="boolean"

      def self.accepts?(value)
        value==true or value==false
      end
    end
  
    class F_Date < F_Field
      @flow_type_name="date"

      #Dates are input as milliseconds from 1970
      def self.accepts?(value)
        value.is_a? Integer or value.to_s =~ /^[0-9]+$/
      end
    end

    class F_Integer < F_Field
      @flow_type_name="integer"

      def self.accepts?(value)
        value.is_a? Integer or value.to_s =~ /^[0-9]+$/
      end
    end
 
   class F_String < F_Field
      @flow_type_name="string"

      def self.accepts?(value)
        value.is_a? String
      end
    end

    class F_Path < F_Field
      @flow_type_name="path"

      def self.accepts?(value)
        value.is_a? String and value.start_with? '/'
      end
    end

    class F_BaseMap < F_Field
      @flow_type_name="map"

      def self.accepts?(value)
        value.is_a? Hash
      end
    end

    class F_Email < F_Field
      @flow_type_name="email"
      #This isn't anywhere near complete self.checking, which is too complicated to be worth it,
      #but if this passes you probably intended it to be an ameil.
      def self.accepts?(value)
        value =~ /^.+@[^\.]+\..*$/
      end
    end
    
    class F_ObjectId < F_Field
      @flow_type_name="id"

      #accepts any string made up of exactly 24 standard hex chars
      #(case-insensitive)
      def self.accepts?(value)
        value =~ /^[0-9a-fA-F]{24}$/
      end
    end
    
    class F_Url < F_Field
      @flow_type_name="url"

      def self.accepts?(value)
        value =~ /^#{URI.regexp}$/
      end
    end
    
    class F_Collection < F_Field
      @flow_type_name="list"
      @collection_type=nil

      def self.accepts?(v)
        v.is_a? Array and ( @collection_type.nil? or v.all? { |i| @collection_type.accepts? i} )
      end  
      
      def self.of(name,collection_type)
        klazz = Class.new F_Collection do
          @collection_type=collection_type
        end
        Object.const_set name, klazz
      end

    end
    
    # --- composite fields ---
    class F_Map < F_Field
      @flow_type_name="map"
      @map={}
      
      def self.accepts?(v)
        v.is_a?Hash and (@map.nil? or self.map_match(v,@map))
      end  

      
      def self.of(name, values)
        klazz=Class.new F_Map do
          
          def self.inject(m)
            return nil if m.nil?
            m.inject({}) { |k,(m,n)| k[m]=inject(n); k }
          end

          @map=self.inject(values)
          @flow_type_name=name
        end
        Object.const_set name.capitalize, klazz
      end
      
      def self.map
        @map
      end
      #input map follows the structure of the reference format.
      #extra keys that don't exist in the reference format throw
      #an argument error
      #
      #missing keys is allowed
      protected
      def self.map_match(m,ref)
        m.each do |k,v|
          raise ArgumentError,"Bad field #{k.inspect} on #{self}" if !ref.has_key?(k) 
          inner_ref=ref[k]
          if !inner_ref.nil?
            map_match(v, inner_ref)
          end
        end
      end
      
      def self.array_match(m,key,matcher)
        if (m.nil? or !m.has_key?(key)) 
          return true
        end
        m[key].each { |i| matcher.accepts? i}
      end
    end
    
    class F_Flags < F_Field
    end
    
    class F_Transform < F_Map
      @map={"function"=>nil,"copyAll"=>nil, "joins"=>nil}
      @join_map={"path"=>nil, "filter"=>nil, "copyAll"=>nil,"sort"=>nil}
      @flow_type_name="transform"

      def self.accepts?(v)
        self.map_match(v,@map) and self.accepts_joins?(v)
      end
      
      def self.accepts_joins?(v)
        if v.has_key? "joins"
          v["joins"].each { |i| map_match(i, @join_map)}
        end
      end
    end
      
    class F_Actions < F_Map
      @flow_type_name="map"
      @map={"delete"=>nil,"dropRead"=>nil,"dropDelete"=>nil,"read"=>nil,"dropWrite"=>nil,"write"=>nil}
    end

    class F_Creator < F_Map
      @flow_type_name="map"
      @map={"fname"=>nil, "lname"=>nil, "alias"=>nil,"application"=>nil}
    end
    
    class F_Permissions < F_Map
      @flow_type_name="permissions"
      @map={"read"=>{"value"=>nil, "access"=>nil, "type"=>nil},"write"=>{"value"=>nil, "access"=>nil, "type"=>nil},"delete"=>{"value"=>nil, "access"=>nil, "type"=>nil}}
    end
  
    class F_ApplicationTemplate < F_Map
      @flow_type_name="applicationTemplate"
      @flow_template = F_Map.of("flowTemplate",
                                {"name"=>nil,
                                  "displayName"=>nil, 
                                  "dropElements"=>nil, 
                                  "description"=>nil, 
                                  "permissions"=>{"read"=>nil,"write"=>nil, "delete"=>nil},
                                  "dropPermissions"=>{"read"=>nil,"write"=>nil,"delete"=>nil}
                                })
      @flow_template.class_eval do
        @drop_template = F_Map.of("dropTemplate",["name", "description","class","required"])
        def self.accepts?(v)
          super and self.array_match(v,"dropElements", @drop_template)
        end
      end

      @track_template = F_Map.of("trackTemplate",["from","to","filter","transformFunction"])
      @track_template.class_eval do
        def self.accepts?(v)
          super and  F_Transform.accepts?(v["transformFunction"]) if v.has_key? "transformFunction"
        end
      end

      def self.accepts?(v)
        self.array_match(v, "userFlows", @flow_template) and self.array_match(v,"userTracks", @track_template)
      end

    end

    class F_DropId < F_Field;end
    
    class F_Location < F_Field;end
    
    class F_Flags < F_Field;end
  
    class F_Constraints < F_Field;end

    class F_Ratings < F_Field;end
    
  end
end
