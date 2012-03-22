require 'test/unit'    
require 'rubygems'
require 'flow'
require 'json'

module TestBase
  def contents(filename)
    path="#{File.dirname(__FILE__)}/../#{filename}"
    open(path).readlines().join('')
  end

  def compare(m1,m2)
    errors=[]
    m1 = m1.nil? ? {} : m1
    m2 = m2.nil? ? {} : m2

    m1.each { |k,v|
      if ! (m2.has_key? k )
        errors.push "#{self} no key for #{k}-#{v}"
      else
        v2=(m2.has_key? k) ? m2[k] : nil
        if v != v2
          if (v2.is_a? Hash and v.is_a? Hash)
            compare(v,v2)
          else
            errors.push "value for key #{k} !=: #{v} != #{v2}"
          end
        end
      end
    }
    if (m2.keys - m1.keys).size > 0
      errors.push "keys in dest not in src: #{m2.keys - m1.keys}"
    end
    
    if errors.size > 0
      errors.each { |i| puts i }
    end
    
    errors.size == 0

  end
  
  def test_json(type, file)
    m=JSON.parse(contents(file))
    obj=type.new(m)
    assert_not_nil obj
    assert(compare(m,obj.to_h()))
  end
end
   
