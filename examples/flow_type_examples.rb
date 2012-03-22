require 'flow'
require 'logger'


bob =  Flow::Credentials.new("4da4d1f6c528272a64ce1a5f", "lFzxYH4rQ5","4da4d1f5c528272a64ce1a50")
# To return flow domain objects hints should be set to false (the
# default). Hinting is only useful at the moment if you want to use 
# the raw api to handle your requests
Flow.connect("http://ec2.flow.net:8080", bob, {:hints=>false, :references=>false})
Flow.logger=Logger.new("/Users/stevenbenjamin/Desktop/rb.out")
i=Flow::Identity.find_by_id(bob.id)


# some sample domain objects

#----------------USER-----------------------
u=Flow::User.new("password"=>"crap","email"=>"zzaz@you.com","permissions"=>{"read"=>{"value"=>true}}, "defaultIdentity"=>{"alias"=>"zaz"})


#----------------DROP-----------------------
d=Flow::Drop.new("path"=>"/identity/ivannaflow/raw-music-input","elems"=>{"trackid"=>"3336666","stationid"=>"7653","source"=>"remote","title"=>"value"})


#----------------IDENTITY--------------------
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

#----------------FLOW-----------------------
f=Flow::Flow.new("icon"=>"http://test.test.com/23432342.png",
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



#----------------TRACK----------------------
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

#----------------APP------------------------
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




#----------------COMMENT------------------------
comment=Flow::Comment.new("text"=>"This is the text of my comment",
                           "dropId"=>"123456123465123456123456",
                           "flowId"=>"123456123465123456123456",
                           "title"=>"My Comment title",
                           "description"=>"MY Comment Description")
#---------------FILE-----------------------                         
f2=Flow::File.new("filename"=>@@filename)
r=f2.save()
f2=Flow::File.new(r.body)
Flow::File.new(r.body).url
=> "http://tfile.flow.net/get/4f20c859e4b097eb8fafa756"

#==============XMPP================
#client is initialized with the alias of the credentialed
#identity and a callback to be invoked when a drop is received.
@@client=Flow::XMPP::Client.new("myflowalias") { |drop | print drop }

begin
  EM.run do
    @@client.start
    @@client.subscribe "123456123456123456123456" # some random flow id
  end
end

