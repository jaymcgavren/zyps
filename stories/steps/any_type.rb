
require 'spec/story'
require 'zyps'

load File.join(File.dirname(__FILE__), '..', 'lib', 'object_manager.rb')
load File.join(File.dirname(__FILE__), '..', 'lib', 'utility.rb')

include Zyps


steps_for(:any_type) do
  Given /(?:given )?([\w\s]+)/ do |subject|
    ObjectManager.instance.resolve_objects(subject)
  end
  Given /(?:given )?([\w\s]+?) with an? (.+?) of "(.+?)"/ do |subject, attribute_name, value|
    ObjectManager.instance.resolve_objects(subject).each {|s| s.method("#{attribute_name}=").call(convert(value))}
  end
  Given /(?:given )?([\w\s]+?) with an? (.+?) of "(.+?)" and an? (.+?) of "(.+?)"/ do |subject, attribute1, value1, attribute2, value2|
    ObjectManager.instance.resolve_objects(subject).each do |s|
      s.method("#{attribute1}=").call(convert(value1))
      s.method("#{attribute2}=").call(convert(value2))
    end
  end
  Given /(?:given )?([\w\s]+?) has (.+?)/ do |subject, target|
    ObjectManager.instance.resolve_objects(subject).each do |s|
      ObjectManager.instance.resolve_objects(target).each do |t|
        s << t
      end
    end
  end
  When /(?:when )?([\w\s]+?) (?:is|are) (?:added|assigned) to ([\w\s]+?)/ do |subject, target|
    ObjectManager.instance.resolve_objects(subject).each do |s|
      ObjectManager.instance.resolve_objects(target).each do |t|
        t << s
      end
    end
  end
  When /(?:when )?([\w\s]+?) (?:is|are) removed from ([\w\s]+?)/ do |subject, container|
    ObjectManager.instance.resolve_objects(subject).each do |s|
      ObjectManager.instance.resolve_objects(container).each do |t|
        t.remove(s)
      end
    end
  end
  Then /(?:then )?([\w\s]+?) should be added to ([\w\s]+?)/ do |subject, target|
    ObjectManager.instance.resolve_objects(subject).each do |s|
      ObjectManager.instance.resolve_objects(target).each do |t|
        t.members.should contain(s)
      end
    end
  end
  Then /(?:then )?([\w\s]+?) should have an? ([\w\s]+?) of "(.+?)"/ do |subject, attribute, value|
    ObjectManager.instance.resolve_objects(subject).each do |s|
      method_name = attribute.split(/\s+/).map{|w| w.downcase}.join('_')
      s.method(method_name).should == convert(value)
    end
  end
  Then /(?:then )?([\w\s]+?) should raise an? (.* )?error/ do |subject, error_type|
    ObjectManager.instance.resolve_objects(subject).each do |s|
      s.should raise_error(error_type.strip)
    end
  end
end


