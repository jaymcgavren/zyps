
require 'spec/mocks'
require 'spec/story'
require 'zyps'
require 'zyps/actions'
require 'zyps/conditions'


load File.join(File.dirname(__FILE__), '..', 'lib', 'object_manager.rb')
load File.join(File.dirname(__FILE__), '..', 'lib', 'utility.rb')


include Zyps




steps_for(:all) do

  #TODO: This is a total kludge.
  Given /an environment/ do
    @om = ObjectManager.new
    @environment = @om.resolve_objects("an environment").first
    def add_to_environment(object)
      @environment << object
      object
    end
    @om.on_create("target") {add_to_environment Creature.new}
    @om.on_create("creature") {add_to_environment Creature.new}
    @om.on_create("game object") {add_to_environment GameObject.new}
  end

  Given /(an? (?:creature|game object|target|behavior|color|location|vector|clock))/i do |subject|
    @om.resolve_objects(subject)
  end
  Given /(an? (?:creature|game object|target|behavior|color|location|vector|clock)) with an? (.+?) of "(.+?)"/i do |subject, attribute_name, value|
    @om.resolve_objects(subject).each {|s| s.method("#{attribute_name}=").call(convert(value))}
  end
  Given /(an? (?:creature|game object|target|behavior|color|location|vector|clock)) with an? (.+?) of "(.+?)" and an? (.+?) of "(.+?)"/i do |subject, attribute1, value1, attribute2, value2|
    @om.resolve_objects(subject).each do |s|
      s.method("#{attribute1}=").call(convert(value1))
      s.method("#{attribute2}=").call(convert(value2))
    end
  end

  Given /(a (?:creature|game object|target)) whose location is "([\d\.]+)", "([\d\.]+)"/i do |subject, x, y|
    location = Location.new(x.to_f, y.to_f)
    @om.resolve_objects(subject).each do |s|
      s << location
    end
  end
  
  Given /(a (?:creature|game object|target)) whose vector has a speed of "([\d\.]+)" and an? (?:angle|pitch) of "([\d\.]+)"/i do |subject, speed, pitch|
    vector = Vector.new(speed.to_f, pitch.to_f)
    @om.resolve_objects(subject).each do |s|
      s << vector
    end
  end
  
  Given /(.+?) has a (.+?) value of "(.+?)"/i do |subject, attribute_name, value|
    @om.resolve_objects(subject).each {|s| s.method("#{attribute_name}=").call(convert(value))}
  end

  
  Given /(an? \w+? (?:action|condition)) with an? (\w+) of "(.+)?"/i do |subject, attribute, value|
    @om.resolve_objects(subject).each do |s|
      s.method("#{attribute}=").call(convert(value))
    end
  end

  Given /(an? \w+? (?:action|condition)) with an? (\w+) of "([\d\.]+)" and an? (\w+) of "([\d\.]+)"/i do |subject, attribute1, value1, attribute2, value2|
    @om.resolve_objects(subject).each do |s|
      s.method("#{attribute1}=").call(convert(value1))
      s.method("#{attribute2}=").call(convert(value2))
    end
  end
  
  When /(.+?) (?:is|are) (?:added|assigned) to (.+?)/i do |subject, target|
    @om.resolve_objects(subject).each do |s|
      @om.resolve_objects(target).each do |t|
        t << s
      end
    end
  end

  When %Q{the environment interacts} do
    @om.resolve_objects('the environment').each {|s| s.interact}
  end
  
  When /"([\d\.]+)" seconds? elapses?/i do |seconds|
    #Monkey-patch Clock to return the given number of seconds.
    Clock.class_eval "def elapsed_time; #{seconds}; end"
  end

  
  Then /(.+?) should have an? (.+?) value of "(.+?)"/i do |subject, attribute_name, value|
    @om.resolve_objects(subject).each do |s|
      method_name = attribute_name.split(/\s+/).map{|w| w.downcase}.join('_')
      s.method(method_name).call.should == convert(value)
    end
  end
  
  Then /(\w+)\(\) should (not )?be called on (.+?)/i do |method, negative, subject|
    @om.resolve_objects(subject).each do |s|
      if negative != "not "
        s.should_receive(method.to_sym)
      else
        s.should_not_receive(method.to_sym)
      end
    end
  end
  
  Then /(.+?) should have a location of "([\d\.]+)", "([\d\.]+)"/i do |subject, x, y|
    @om.resolve_objects(subject).each do |s|
      s.location.x.should be_close(x.to_f, 0.01)
      s.location.y.should be_close(y.to_f, 0.01)
    end
  end
  
  Then /(.+?) should have a vector with a speed of "([\d\.]+)" and an? (?:angle|pitch) of "([\d\.]+)"/i do |subject, speed, pitch|
    @om.resolve_objects(subject).each do |s|
      s.vector.speed.should be_close(speed.to_f, 0.01)
      s.vector.pitch.should be_close(pitch.to_f, 0.01)
    end
  end
  
  Then /display (.+?)/i do |subject|
    puts "", "-" * 60
    @om.resolve_objects(subject).each {|s| puts s.to_s}
    puts "-" * 60
  end

  
end
