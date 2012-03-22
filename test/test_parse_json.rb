require 'test/unit'  
require 'flow_test_base' 
class TestParseJson < Test::Unit::TestCase
  include TestBase


  def test_parse_flow
   test_json(Flow::Flow,"samples/json/Flow.json")
  end

  def test_parse_application
   test_json(Flow::Application,"samples/json/Application.json")
  end

  def test_parse_drop
   test_json(Flow::Drop,"samples/json/Drop.json")
  end

  def test_parse_enum
   test_json(Flow::Enum,"samples/json/Enum.json")
  end

  def test_parse_group
   test_json(Flow::Group,"samples/json/Group.json")
  end

  def test_parse_identity
   test_json(Flow::Identity,"samples/json/Identity.json")
  end

  def test_parse_track
   test_json(Flow::Track,"samples/json/Track.json")
  end  


end

	
