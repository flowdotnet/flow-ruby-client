require 'json'
include Flow::Base
module Flow
  class Flow < FlowObject
    @url_key=:flow
    self.create_fields(
      "template"=>F_Constraints,
      "icon"=>F_Url,
      "flags"=>F_Flags,
      "location"=>F_Location,
      "dropPermissions"=>F_Permissions,
      "description"=>F_String,
      "name"=>F_String,
      "path"=>F_Path,
      "permissions"=>F_Permissions,
      "local"=>F_Boolean,
      "filter"=>F_String,
      "ratings"=>F_Ratings)
  end

  class Enum < Flow
    @url_key=:enum
    self.create_fields("values"=>F_Collection.of("EnumValues",F_String),"path"=>F_Path,"name"=>F_String)
  end

  class Identity < FlowObject
    @url_key=:identity
    self.create_fields(
      "lastName"=>F_String,
      "alias"=>F_String,
      "avatar"=>F_Url,
      "appIds"=>F_Collection.of("ApplicationIds",F_ObjectId),
      "creationDate"=>F_Date,
      "groupIds"=>F_Collection.of("GroupIds", F_ObjectId),
      "userId"=>F_ObjectId,
      "permissions"=>F_Permissions,
      "firstName"=>F_String)
  end

  class Group < FlowObject
    @url_key=:group
    self.create_fields(
      "creationDate"=>F_Date,
      "icon"=>F_Url,
      "identityPermissions"=>F_Permissions,
      "description"=>F_String,
      "name"=>F_String,
      "permissions"=>F_Permissions,
      "identities"=>F_Collection.of("IdentityIds",F_ObjectId),
      "displayName"=>F_String)
    
  end

  class Drop < FlowObject
    @url_key=:drop
    self.create_fields(
      "weight"=>F_Integer,
      "flags"=>F_Flags,
      "path"=>F_Path,
      "elems"=>F_ElemsMap,
      "ratings"=>F_Ratings,
      "parentDropId"=>F_String,
      "flowId"=>F_ObjectId,
      "version"=>F_Integer)

    def delete(credentials=nil)
      self.class.delete(@flowId, @id,credentials)
    end

    def self.delete(id, credentials=nil)
      raise NotImplementedError, "Class delete not supported for drops"
    end
    
    def self.delete(flowId, dropId, credentials=nil)
      ::Flow.connection.delete(@url_key, "#{flowId}/#{dropId}", _validate_credentials(credentials))
    end
      
    #Uses default credentials
    def self.filter(flowId,filter,opts={:start=>nil,:limit=>nil,:sort=>nil,:order=>nil,:credentials=>nil})
      _find( "/#{@url_key}/#{flowId}/",filter,opts.reject{|k,v| v.nil? })
    end

    #Retrieve the resource by id
    def self.find_by_id(flowId,dropId,credentials=nil)
      response=::Flow.connection.get(self.url_key, "#{flowId}/#{dropId}", _validate_credentials(credentials))
      self.new(response.body)
    end
    
    def self.find(flowId, criteria,  opts={:start=>nil,:limit=>nil,:sort=>nil, :order=>nil, :credentials=>nil})
      _find( "/#{@url_key}/#{flowId}/",{},opts.reject{|k,v| v.nil? })
    end
    
  end

  class Application < FlowObject
    @url_key=:application
    self.create_fields(
      "icon"=>F_Url,
      "applicationTemplate"=>F_ApplicationTemplate,
      "isDiscoverable"=>F_Boolean,
      "url"=>F_Url,
      "version"=>F_String,
      "groupId"=>F_ObjectId,
      "title"=>F_String,
      "email"=>F_Email,
      "description"=>F_String,
      "name"=>F_String,
      "permissions"=>F_Permissions,
      "secret"=>F_String,
      "displayName"=>F_String,
      "isInviteOnly"=>F_Boolean,
      "key"=>F_String,
      "bucketRefs"=>F_Collection.of("BucketRefs",F_ObjectId))

  end

  class Track < FlowObject
    @url_key=:track
    self.create_fields(
      "to"=>F_Path,
      "permissions"=>F_Permissions,
      "transformFunction"=>F_Transform,
      "from"=>F_Path,
      "filterString"=>F_String)

  end

  class User < FlowObject
    @url_key=:user
    self.create_fields(
      "middleName"=>F_String,
      "lastName"=>F_String,
      "initialEmail"=>F_Email,
      "password"=>F_String,
      "identityIds"=>F_Collection.of("UserIdentityIds",F_ObjectId),
      "title"=>F_String,
      "email"=>F_Email,
      "permissions"=>F_Permissions,
      "firstName"=>F_String,
      "defaultIdentity"=>Identity)
    
  end

  class Comment < FlowObject
    @url_key=:comment
    self.create_fields(
      "text"=>F_String,
      "hasChildren"=>F_Boolean,
      "deletedBy"=>F_ObjectId,
      "dropId"=>F_ObjectId,
      "flowId"=>F_ObjectId,
      "topParentId"=>F_ObjectId,
      "parentId"=>F_ObjectId,
      "title"=>F_String,
      "description"=>F_String)
    
  end

  class File < FlowObject
    # Largest size file the api will accept from 
    # a client post (in bytes)
    @@MAX_FILE_LENGTH = 10_000_000

    @url_key=:file
    self.create_fields(
      "id"=>F_ObjectId,
      "mimeType"=>F_String,
      "name"=>F_String,
      "filename"=>F_String,
      "contents"=>F_String,
      "reference"=>F_Map.of("media",nil),
      "metadata"=>F_Map.of("map", nil))

    # Several ways to create a file:
    # directly from file name:
    # f=Flow::File.new("/home/me/test.jpg")
    # from a response
    # r=f.save()
    # f=Flow::File.new(r.body)
    def initialize(f)
      if f.is_a? String
        super({"filename"=>f})
      else
        super(f)
      end
    end
       
    def save(credentials=nil)
      #discover value from file
      if @filename 
        @name = ::File.basename(@filename) unless @name
        @contents = Base64.encode64(::File.read(@filename)) unless @content or ::File.stat(@filename).size()>@@MAX_FILE_LENGTH
        @contents = nil if @content.length > @@MAX_FILE_LENGTH unless @content.nil?
      end
      super
    end

    def url
      @reference["url"] unless @reference.nil?
    end

  end
end
