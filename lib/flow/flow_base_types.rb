module Flow
  module Base
    # trying to add a field to a FlowObject that doesn't exist
    class UnknownFieldError < ArgumentError
    end

    # Basic behavior for flow domain objects.
    #
    # This is simply behavior to wrap json calls insuring correct arguments and endpoints
    # for given request types.
    #
    # fields that don't match accepted arguments will be ignored
    class FlowObject < F_Field
      @fields = {
        "id"=>F_ObjectId,
        "creatorId"=>F_ObjectId,
        "creationDate"=>F_Date ,
        "lastEditorId"=>F_ObjectId,
        "lastEditDate"=>F_Date,
        "creator"=>F_Creator,
        "actions"=>F_Actions}
      
      def initialize(m)
        _set(m)
      end
      
      def self.create_fields(fmap)
        @fields=FlowObject.fields.merge(fmap)
        fmap.each do |k,v| 
          self.class_eval { attr_accessor k.to_sym }
        end
      end
      
      attr_accessor :id,:creatorId,:creationDate,:creator,:lastEditorId,:lastEditDate,:actions
      #Connect with the initialized credentials or per-request
      #supplied credentials. After saving the object will be properly populated with the newly created id.
      #
      # @param [credentials] optional per-request credentials
      #
      # @return [Flow::Response] A Response object for access to the raw request and headers.
      # @example save a Drop
      #       d=Flow::Drop.new("path"=>"/some/path","elems"=>{"title"=>"drop title"})
      #       d.save()
      #       d.id
      #       =>"1234567890abcd1234567890"
      def save(credentials=nil)
        begin
          creds = FlowObject._validate_credentials(credentials)
          if @id
              _id=@id
              @id=nil
              response =::Flow.connection.put(self.class.url_key,_id,to_json,creds)
          else
              response=::Flow.connection.post(self.class.url_key,to_json,creds)
          end
          _set(response.body) if response.success
        end
        response
      end
      
      def delete(credentials=nil)
        self.class.delete(@id,credentials)
      end
      
      def self.delete(id, credentials=nil)
        ::Flow.connection.delete(@url_key, id, _validate_credentials(credentials))
      end

      #Retrieve the resource by id
      #
      # @raise: ArgumentError if credentials to be used (provided or
      # global) are invalid.
      # @param id [String] string form of the bosn id, a 24 character
      # hex string
      # @param credentials [Flow::Credentials] (nil) an optional set of
      # credentials if you wish to override the global values available
      # in (see Flow#credentials).
      def self.find_by_id(id, credentials=nil)
        response= ::Flow.connection.get(self.url_key, id, _validate_credentials(credentials))
        self.new(response.body) if response.success
      end
      
      #Retrive matching values via full-text search.
      #
      # @param text [String] Full-text (Lucene) search
      # @option opts [Integer] :start (0) Start of search result
      # @option opts [Integer] :limit (20) Maximum number of results returned
      # @option opts [String] :sort (nil) Field to sort by
      # @option opts [String] :order (nil) "asc" or "desc"
      # @option opts [Flow::Credentials] :credentials (nil) Optional credentials to override the global value
      def self.text_search(text, opts={:start=>nil,:limit=>nil,:sort=>nil, :order=>nil, :credentials=>nil})
        _find("/#{self.url_key}",{"query"=>text}, opts)
      end

      #Retrive matching values via field matching.
      #
      # @param criteria [Hash] Field match values
      # @option opts [Integer] :start (0) Start of search result
      # @option opts [Integer] :limit (20) Maximum number of results returned
      # @option opts [String] :sort (nil) Field to sort by
      # @option opts [String] :order (nil) "asc" or "desc"
      # @option opts [Flow::Credentials] :credentials (nil) Optional credentials to override the global value
      def self.find(criteria,  opts={:start=>nil,:limit=>nil,:sort=>nil, :order=>nil, :credentials=>nil})
        #criteria map is either a json map of the criteria object or
        #expression of the form: {:operator:"regex",:operand:"value"}
        #for any regex obejcts
        c=criteria.inject({}) { |m, (k,v)| 
          field=@fields[k]
          if (v.class == Regexp)
            rgxp=v.inspect
            m[k]={:type=>"expression",:value=>{:operator=>"regex",:operand=>"#{rgxp.slice(1,rgxp.length-2)}"}}
          else
            m[k]={:type=>field.type_name,:value=>v} if !(field.nil? or field.type_name.nil?)
          end
          m
        }
        _find("/#{self.url_key}",{:criteria=>JSON.generate(_criteria_map(criteria))}, opts)
      end

      
      def self.url_key
        @url_key
      end
      
      def self.fields
        @fields
      end
      
      def self.from_xml_doc(doc)
        instance=self.new({})
        
        doc.children.select{ |node| node.element?}.each { |elem|
          field = @fields[elem.name]
          if !field.nil?
            value_as_map=parse_xml_element(elem)
            value=field.extract_if_valid(value_as_map)
            instance.instance_variable_set("@#{elem.name}", value)
          end
        }
        instance
      end

      def to_json(*a)
        to_h.to_json(*a)
      end
      
      def inspect
        "#{self.class}:#{to_h.inspect}"
      end
      
      def self.accepts?(value)
        value.is_a? Hash and value.keys.all? { |i| @fields.has_key? i }
      end

      def to_h
        m={}
        self.class.fields.each do |key,field|
          val = instance_variable_get("@#{key}")
          m[key]=field.hint(val) unless val.nil?
        end
        m
      end

      protected

      def self._validate_credentials(provided_credentials)
        if provided_credentials.nil? and ::Flow.credentials.nil?
          raise ArgumentError, "No credentials"
        end
        (provided_credentials unless provided_credentials.nil?) or ::Flow.credentials
      end

      def self._criteria_map(criteria)
        criteria.inject({}) { |m, (k,v)| 
          field=@fields[k]
          if (v.class == Regexp)
            rgxp=v.inspect
            m[k]={:type=>"expression",:value=>{:operator=>"regex",:operand=>"#{rgxp.slice(1,rgxp.length-2)}"}}
          else
            m[k]={:type=>field.type_name,:value=>v} if !(field.nil? or field.type_name.nil?)
          end
          m
        }
      end

      def self._find(url,params,opts)
        creds=_validate_credentials(opts[:credentials])
        header=Header.new(creds, 'json','json')
        resp = ::Flow.connection.send('GET',url,header,nil, params.merge!(opts.reject{|k,v| v.nil? }))
        resp.body.map { |i| self.new(i)} if resp.success
      end
      
      def _set(m)
        fields = self.class.fields
        m.each do |k,v|
          if fields.has_key?(k)
            v2=fields[k].extract_if_valid(v)
            instance_variable_set("@#{k}", v2)
          end
        end
      end
      
      def self.parse_xml_element(d)
        h={}
        if d.has_attribute? "type"
          h["type"]=d.get_attribute("type")
          if d.children.size == 1
            h["value"]=d.inner_text
          else
            m={}
            h["value"]=m
            d.children.each do |i|
              if i.element?
                m[i.name]=parse_xml_element(i)
              end
            end
          end
        end
        h
      end

    end

  end
end
