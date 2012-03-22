require 'net/http'
require 'cgi'
require 'uri'
require 'digest/sha1'
require 'json'
require 'base64'

module Flow
  
  #Global connection specifications.
  @@connection=nil
  #Gobal credentials. This can optionally be
  #overwritten with provided credentials in all operations.
  @@credentials=nil
  #Debug logger. set for logging output 
  @@logger=nil
  def self.logger
    @@logger
  end

  def self.logger=(logger)
    @@logger=logger
  end

  def self.log(*s)
    if !@@logger.nil?
      s.each { |i| @@logger.debug i }
    end
  end

  def self.credentials
    @@credentials
  end

  def self.credentials=(creds)
    @@credentials=creds
  end
  def self.connection
    @@connection
  end
  
  #set the global connection and credentials
  #
  # @param url [String] Flow connection url
  # @option opts [Boolean] :hints (false) Whether to respond with
  # hints. The client is designed to work without hints - they will
  # only work for raw data.
  # @option opts [Boolean] :references (false) Also retrieve
  # references data (extra data provided by the api). This data will
  # be available in the Response object references member.
  def self.connect(url, creds, opts={:hints=>false, :references=>false})
    @@connection=Connection.new(url, opts)
    @@credentials=creds
  end  


  # Connection information to flow data. Connection does not hold an open connection.
  class Connection
    URI_REGEX = Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")
    DOMAIN_TYPES = [:flow, :drop, :comment, :application, :track,:group, :identity, :user, :file, :enum]
    
    #Create connection specifications. 
    #
    # @param [String] url - The connection string.
    # @param [Hash] options - :hints - Specifies whether to use type hinting
    # in responses. The client normally uses the default value of
    # false, the option is provided here for clients that would prefer
    # to use raw json
    # :references - return additional references in the response header
    def initialize(url, options)
      @url = URI.parse(url)
      @hints = options[:hints]
      @references=options[:references]
    end
    
    # returns Net::HttpResponse
    def post(type, content, credentials, request_type="json",response_type="json")
      ::Flow.log("posting", content)
      send('POST',"#{as_member_of(type, DOMAIN_TYPES)}", Header.new(credentials, request_type, response_type), content)
    end  
    
    def get(type, id, credentials, response_type="json",params=nil)
      send('GET',"#{as_member_of(type,  DOMAIN_TYPES)}/#{id}", Header.new(credentials, 'json', response_type),nil,params)
    end
    
    def put(type, id, content, credentials, request_type="json", response_type="json")
      send('PUT',"#{as_member_of(type,  DOMAIN_TYPES)}/#{id}", Header.new(credentials, request_type, response_type), content)
    end
    
    def delete(type, id, credentials, response_type="json")
      send('DELETE',"#{as_member_of(type, DOMAIN_TYPES)}/#{id}", Header.new(credentials, 'none', response_type))
    end

    def send(method, path, header, content=nil, params=nil)
      http = Net::HTTP.new(@url.host,@url.port)
      url="#{@url.path}/#{path}?hints=#{@hints ? 1 : 0}&refs=#{@refs ? 1 : 0}"
      if !params.nil?
        param_string = params.collect {|k,v| "#{k}=#{URI.escape(v.to_s,URI_REGEX)}"}.join("&")
        url="#{url}&#{param_string}"
      end
      ::Flow.log("SEND", ["method",method], ["path",url], ["content",content], ["header",header])
      Response.new(http.send_request(method, url, content, header.to_m))
    end    
    
    attr_accessor :url, :references, :hints
    
    protected

    def to_json(m)
      m.reject { |k,v| v.nil?}.to_json
    end
    
    def encode(s)
      CGI.escape(s)
    end
    
    def as_member_of(s, keys)
      raise ArgumentError.new("[#{s}] can only be one of [#{keys.join(',')}]") if !keys.member?(s)
      s
    end
  end
  
  
    # The Header wraps the header parameters required to make a valid request.
  class Header
    
    MIME_TYPES = {"json"=>"application/json", "xml"=>"text/xml", "none"=>nil}
    
    #request_type and response type can be either "json" or "xml"
    def initialize(credentials, request_type="json", response_type="json")
      @c = credentials
      @request_type= request_type
      @response_type= response_type
      @ts = timestamp
    end
    
    # return the map form of the header. Values are
    # * "Accept"=>"application/json" or "text/xml"
    # * "X-Actor"=>credentials id
    # * "X-Key"=>credentials key
    # * "X-Timestamp"=>timestamp used in calculating signature
    # * "X-Signature"=>signature calcualted from the credentials
    # * "Content-type"=>"application/json" or "text/xml"
    # *  "USER-AGENT"=>"Flow ruby client v.00000001"
    def to_m
      m =
      {
        "Accept"=>(MIME_TYPES[@response_type] or MIME_TYPES["json"]),
        "X-Actor"=>@c.id,
        "X-Key"=>@c.key,
        "X-Timestamp"=>@ts,
        "X-Signature"=>signature,
        "USER-AGENT"=>"Flow ruby client v.00000001"
      }
      m["Content-type"]=(MIME_TYPES[@request_type] or MIME_TYPES["json"]) unless request_type == "none"
      puts "request_type #{m.inspect}"
      m
   end

    attr_accessor :request_type, :response_type
    
    def to_s
      to_m.inspect
    end

    private

    def timestamp
      (Time.now.to_f * 1000).to_i.to_s
    end
    
    def signature
      Digest::SHA1.hexdigest("x-actor:#{@c.id}x-key:#{@c.key}x-timestamp:#{@ts}#{@c.secret}")
    end
  end
  
  # Credentials encompass a key and secret from the requesting application as
  # well as the id of the identity making the request.
  class Credentials 
    def initialize(key, secret, id)
      @key=key
      @secret=secret
      @id=id
    end
    
    attr_accessor :key, :secret, :id
    
  end
  # Wrapper for a single json response from the flow api. 
  # Retrieve header information with response.header.
  # The header will contain any server messages or errors from the request.
  #
  # e.g.
  # <tt>
  # { "ok":true,
  #   "messages":[[null,"Your request has been processed successfully. A new resource has been created."]],
  #   "errors":[]  
  # }
  # </tt>
  class Response
    def initialize(r)
      @code = r.code
      ::Flow.log("Response", r.body)
      @values = JSON.parse(r.body)
    end
    
    def id
      from_values(@values, ["body","id","value"])
    end
    
    def body
      @values["body"]
    end
    
    def head
      @values["head"]
    end

    def success
      head["ok"]
    end 
    
    def errors
      head["errors"]
    end
    
    def messages
      head["messages"]
    end
    
    # This value will only be populated if references are requested.
    def references
      @values["references"]
    end

    def status
      head["status"]
    end

    def json
      JSON.pretty_generate(@values)
    end

    attr_accessor :code, :values
    
    private
    def from_values(m, keys)
      keys.inject(m) { |m, c| m=m[c] if m }
    end
  end

end
