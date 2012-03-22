# Flow Client Library
 
The flow ruby library provides convenient wrappers to access the flow's json or xml based api. For more information on the api see our [developers site](http://dev.flow.net).

Example useage:

    require 'flow'
    key,secret,id ="4da74d1e8065de1c446af3a9","8isUKqotp0","4da4e0718065931503b37ece"
    credentials = Flow::Credentials.new(key, secret, id)
    Flow.connect("http://api.flow.net", credentials)
    i=Flow::Identity.find_by_id(bob.id)

This driver requires the blather gem for xmpp access.

# Retrieving Objects

Several types of find syntax are supported. 

## Retrieving by field match
    i=Flow::Identity.find("path"=>/bob/,"creatorId"=>"4f2963ec44704d54436baa71") 
### support for paging, sorting, and alternative credentials:
    i=Flow::Identity.find_by_id("4f296429c2346d302830dba7",{:limit=>5,:start=>5,:sort=>"creationDate",:order=>"asc", :credentials=>someOtherFlowCredentials})

## Full text search
    i=Flow::Flow.text_search("some random text")

## Drops also support retrieval using Flow's [filter syntax](http://flow.net/documentation/api/filter)
    drops=Flow::Drop.filter("someflowid","A>10 && B<20", {:limit=>10})

# Basic CRUD Operations
## Create
    d=Flow::Drop.new("path"=>"/identity/somebody/mymusic","elems"=>{"trackid"=>"3336666","stationid"=>"7653","source"=>"remote","title"=>"value"})
    r=d.save()
    #object is populated with new id
    d.id
    =>"4f296268a7b349f5183af568"
    #returns a Flow::Response object with access to raw response values 
    r.header
    => {"messages"=>[[nil, "Your request has been processed successfully. A new resource has been created."]], "errors"=>[], "ok"=>true}

## Update
    d.elems["trackid"]="4441233"
    d.save()
## Delete
    d.delete()
or
    Flow::Drop.delete(d.id)
    
## Read
    i=Flow::Identity.find_by_id("4f296429c2346d302830dba7")

    
# Sample Flow Domain Objects

Flow objects are populated as maps with the appropriate fields.

## User
    u=Flow::User.new("password"=>"mypassword","email"=>"my.email@some.place","permissions"=>{"read"=>{"value"=>true}}, "defaultIdentity"=>{"alias"=>"iwillbeknownas"})


## Drop
    d=Flow::Drop.new("path"=>"/identity/somebody/mymusic","elems"=>{"trackid"=>"3336666","stationid"=>"7653","source"=>"remote","title"=>"value"})


## Identity
    ident=Flow::Identity.new(
    "lastName"=>"testname",
    "alias"=>"testalias",
    "avatar"=>"http://this.wont.work.com",
    "appIds"=> ["4f19996cda06a26a1882fa6a", "4f1985fdda065d9c1fdf4da4"],
    "groupIds"=> ["4f1985fdda065d9c1fdf4dad", "000000000000000000000003"],
    "userId"=>"123456123456123456123456",
    "permissions"=>{"read"=>{"value"=>true}},
    "firstName"=>"testfname")
    resp=ident.save()

## Flow
    f=Flow::Flow.new("icon"=>"http://icons.mysitemyway.com/wp-content/gallery/3d-glossy-green-orbs-icons-transport-travel/thumbs/thumbs_104734-3d-glossy-green-orb-icon-transport-travel-transportation-airplane10-sc44.png",
       "template"=>[{
                      "class:"=>"string",
                      "required"=>false,
                      "inferred"=>false,
                      "name"=>"sourcename",
                      "displayName" =>"Source",
                      "description" =>"What did this come from?"
                    },
                    {
                      "class"=>"string",
                      "required"=>true,
                      "inferred"=>false,
                      "name"=>"directions",
                      "displayName"=>"Directions",
                      "description"=>"How do you mix the ingredients together?"
                    }],
      "location"=>{"lat"=>41.9,"lon"=>-86.1,"specifiers"=>{"city"=>"New York", "street"=>"410 Broadway","state"=>"NY", "zip"=>"11211"}},
      "dropPermissions"=>{"read"=>{"access"=>"exclude","value"=>[]},"write"=>{"access"=>"exclude","value"=>[]},"delete"=>{"access"=>"include","value"=>[]}},
      "description"=>"This is where a description of the flow would go",
      "name"=>"this is the name of the flow to be created",
      "path"=>"/test/sometestflow",
      "permissions"=>{"read"=>{"value"=>["000000000000000000000001","4f1985fdda065d9c1fdf4daa"],"access"=>"exclude"},
                      "write"=>{"value"=>[],"access"=>"exclude"},
                      "delete"=>{"value"=>["4f1985fdda065d9c1fdf4db3","4f19996cda06a26a1882fa6a"],"access"=>"include"}},
      "local"=>true,
      "filter"=>"sourcename =~/A/" )


## Track

    track=Flow::Track.new("to"=>"/identity/bob/2222",
                      "from"=>"/identity/bob/23333",
                      "filterString"=>"A > 10",
                      "permissions"=>{
                        "read"=>{"access"=>"exclude","value"=>[]},
                        "write"=>{"access"=>"exclude","value"=>[]},
                        "delete"=>{"access"=>"include","value"=>[]}},
                      "transformFunction"=>{
                        "copyAll"=>true,
                        "function"=> "function(d1,d2,d3,d4) {d1['a']=d3['b']; }",
                        "joins"=>[{"path"=>"/identity/bob/qqqq",
                                    "filter"=>"brand ==\"${d1['brand']}\"",
                                    "copyAll"=>true,
                                    "sort"=>"a asc"
                                  },
                                  {"path"=>"/identity/bob/www", 
                                    "filter"=>"brand ==\"${d1['brand']}\"",
                                    "copyAll"=>false
                                  }
                                 ]})

## Application

    app=Flow::Application.new("displayName"=>"ABC displayName",
                          "description"=>"ABC Description",
                          "email"=>"feedback@myapp.com",
                          "icon"=>"http://file.flow.net/get/123456123456123456123456",
                          "isDiscoverable"=>true,
                          "name"=>"myappname",
                          "permissions"=>{
                            "write"=>{"value"=>[],"access"=>"include"},
                            "delete"=>{"value"=>[],"access"=>"include"},
                            "read"=>{"value"=>[],"access"=>"include"}},
                          "applicationTemplate"=>{
                            "userFlows"=>[
                                            {"name"=>"appname",
                                             "displayName"=>"My Application Name",
                                             "description"=>"some description text",
                                             "permissions"=>{},
                                             "dropPermissions"=>{"read"=>"public","write"=>"private", "delete"=>"app_only"},
                                            "dropElements"=>[
                                                             {"name"=>"A",
                                                               "description"=>"descriptionofa",
                                                               "class"=>"string",
                                                               "required"=>true}
                                                            ]}
                                          ],
                            "userTracks"=>[
                                           {"to"=>"/identity/bob/2222",
                                           "from"=>"/identity/bob/23333",
                                             "filter"=>"A > 10",
                                             "transformFunction"=>{
                                               "function"=>"function(d1,d2,d3,d4){d1['a']=d3['b']; }",
                                               "copyAll"=>true,
                                               "joins"=>[
                                                         {"path"=>"/identity/bob/qqqq",
                                                           "filter"=>"brand ==\"${d1['brand']}\"",
                                                           "copyAll"=>true,
                                                           "sort"=>"a asc"
                                                         }]}}
                                           ]
                          })

## Comment
    comment=Flow::Comment.new("text"=>"This is the text of my comment",
                           "dropId"=>"123456123465123456123456",
                           "flowId"=>"123456123465123456123456",
                           "title"=>"My Comment title",
                           "description"=>"MY Comment Description")

    f2=Flow::File.new("filename"=>@@filename)
    r=f2.save()
    f2=Flow::File.new(r.body)
    Flow::File.new(r.body).url
    => "http://tfile.flow.net/get/4f20c859e4b097eb8fafa756"

## XMPP
    The xmpp client is initialized with the identity of the credentialed person and a block to be 
    called on drop receive
    @@client=Flow::XMPP::Client.new("steve") { |drop| print drop }

    begin
      EM.run do
      @@client.start
      @@client.subscribe "123456123456123456123456" # some random flow id
    end
