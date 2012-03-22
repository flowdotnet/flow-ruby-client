require 'flow'

secret = "xxxxxxxxxx" 
key = "0123456789012345678991234" 
id = "aaaaaa123e67a4bf5722dc1"

Flow::Credentials.new(key,secret,id)
Flow.connect("http://api.flow.net", creds, {"hints"=>false, "references"=>false})


permissions={
  "read"=>{"value"=>["aaaaaa123e67a4bf5722dc1"],"access"=>"include"},
  "write"=>{"value"=>[], "access"=>"exclude"}, 
  "delete"=>{"value"=>[], "access"=>"exclude"}
}

//user
user_response = c.create_user(creds, "test22@test.com", "thisismypassword", "this_is_thealiasIllbeknownas")
bucket_response = c.create_bucket(creds, "my bucket", "/test/mypath", [{"name"=>"v1", "class"=>"email", "required"=>true}])
track_response = c.create_track(creds, "/test/mypath", "/system", "v1 =~ /a/","") 
group_response = c.create_group(creds,"a group name", permissions )
comment_response = c.create_comment(creds, "000000000000000000000000","000000000000000000000000","00000000000000000000000","a comment title", "this is my comment description", "this is my comment text")
app_response = c.create_application(creds,"myappname", "myapp displya name", "myapp description", "foo@bar.com", "http://foobar.app.com", true, true)
ident_resonse = c.create_identity(creds,"joe", "schmoe", "jschmoe_the_alias",user_id, [], permissions)
file_response = c.create_file(creds, "/Users/stevenbenjamin/Desktop/t1.jpg", "image/jpg")
drop_response = c.create_drop(creds, "/test/mypath", {"v1"=>{"type"=>"string", "value"=>"some junk goes here"}, "b"=>{"type"=>"email", "value"=>"joe@example.com"}})
search_response = c.search(creds, "bee")
query_response = c.query(creds, "bucket", "foo")
query_bucket = c.query_bucket(creds,"000000000000000000000000", "bee")
query_match = c.criteria(creds, "drop", {"a"=>"b", "c"=>"d"})
query_match_bucket = c.criteria_bucket(creds, "000000000000000000000000", {"a"=>"b", "c"=>"d"})
query_filter= c.filter(creds, "000000000000000000000000", "a>1")

