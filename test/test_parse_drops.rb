require 'test/unit'
require 'flow_test_base'
require 'json'

class TestParseDrops < Test::Unit::TestCase
  include TestBase

  def test_parse_xml_drop
    #initialization of the xmpp client requires a valid
    #credentials object to exist.
    Flow.credentials=Flow::Credentials.new("X","X","X")
    client= Flow::XMPP::Client.new("alias")
    c=contents("samples/xml/ExampleXmppDrop.xml")
    drop = client.extract_drop(Nokogiri::XML(contents("samples/xml/ExampleXmppDrop.xml")))
    assert_equal(drop.actions,{"delete"=>"true", "read"=>"true","write"=>"true"})
    assert_equal(drop.path,"/identity/bob/2222")
    assert_equal(drop.creator,{"lname"=>"Siddharta","alias"=>"bob","fname"=>"Bob"})
    assert_equal(drop.elems.keys.sort!,["description","title"])
    #larger drop
    drop = client.extract_drop(Nokogiri::XML(contents("samples/xml/ExampleXmppMultivaluedDrop.xml")))
    assert_equal(drop.elems.keys.sort!,["adate", "aloc", "aurl", "description", "mediaa", "rich", "text", "title", "yn"]) 
  end

  def test_parse_base_types
    raw = contents("samples/drops/unhinted_base_types.json")
    json=JSON.parse(raw)
    drop = Flow::Drop.new(json)
    assert_equal(drop.elems["string"],{"type"=>"string","value"=>"a string"})
    assert_equal(drop.elems.size,6)
    test_base_vals(drop)
  end

  def test_parse_collection_types
    raw = contents("samples/drops/unhinted_collection_types.json")
    json=JSON.parse(raw)
    drop = Flow::Drop.new(json)
    assert_equal(drop.elems["treemap"]["value"].keys, ["A","B"])
    assert_equal(drop.elems["hashmap"]["value"].keys, ["A","B"])
    assert_equal(array_values(drop.elems["arraylist"]["value"]), ["A","B","C"])
    assert_equal(array_values(drop.elems["hashset"]["value"]), ["A","B","C"])
    test_base_vals(drop)
  end

  def test_parse_complex_types
    raw = contents("samples/drops/unhinted_complex_types.json")
    json=JSON.parse(raw)
    drop = Flow::Drop.new(json)
    assert_equal(drop.elems["location"]["value"].keys.sort!,["lat","lon","specifiers"])
    assert_equal(drop.elems["text"]["value"].keys.sort!,["content","format","safe"])
    test_base_vals(drop)
  end

  def test_parse_labelled_types
    raw = contents("samples/drops/unhinted_labelled_types.json")
    json=JSON.parse(raw)
    drop = Flow::Drop.new(json)
    assert_equal(drop.elems["email"],{"type"=>"email","value"=>"oemfjfjaio@test.com"})
    assert_equal(drop.elems.size,6)
    test_base_vals(drop)
  end

  def test_parse_unit_types
    raw = contents("samples/drops/unhinted_unit_types.json")
    json=JSON.parse(raw)
    drop = Flow::Drop.new(json)
    assert_equal(drop.elems.size,3)
    test_base_vals(drop)
  end

  def array_values(l)
    l.collect { |i| i["value"]}.sort!
  end
  
  def test_base_vals(drop)
   types= {"weight"=>Integer,"lastEditorId"=>String,"creatorId"=>String,"lastEditDate"=>Integer,"parentDropId"=>String,"creationDate"=>Integer,"path"=>String,"elems"=>Hash,"ratings"=>Hash,"flowId"=>String,
    "actions"=>Hash}
    types.each do |name,expected_type| 
      actual=drop.instance_variable_get('@'+name)
      assert((actual.is_a? expected_type),"#{name}=>#{expected_type} found #{actual} #{actual.class}" )
    end
  end
end
