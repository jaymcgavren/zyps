require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

require 'zyps'
require 'zyps/actions'
require 'zyps/conditions'
require 'zyps/environmental_factors'

include Zyps


RSpec.describe Environment do
  
  subject do
    Environment.new
  end

  it "should accept GameObjects" do
    subject << GameObject.new << GameObject.new
    subject.object_count.should equal(2) #Can't use have(); doesn't return array.
  end
  
  it "should accept Creatures" do
    subject << Creature.new << Creature.new
    subject.object_count.should equal(2) #Can't use have(); doesn't return array.
  end
  
  it "should accept EnvironmentalFactors" do
    subject << Gravity.new << Gravity.new
    subject.environmental_factor_count.should == 2 #Can't use have(); doesn't return array.
  end
  
  it "should allow copies" do
    copy = subject.copy
    copy.should == subject
  end

  it "should copy GameObjects when copying self" do
    subject << GameObject.new << GameObject.new
    subject.objects.each do |object|
      subject.copy.object_count.should == 2 #Equal...
      subject.copy.objects.should_not satisfy {|objects| objects.any?{|o| o.equal?(object)}} #...but not identical.
    end
  end
  
  it "should move all objects on update" do
    object = GameObject.new(:vector => Vector.new(1, 0))
    subject << object
    clock = Clock.new
    clock.should receive(:elapsed_time).and_return(1)
    subject.clock = clock
    subject.interact
    object.location.should == Location.new(1, 0)
  end
  
  it "should have all objects act on each other" do
    creature_1 = Creature.new
    creature_2 = Creature.new
    subject << creature_1 << creature_2
    creature_1.should receive(:act).with([creature_2])
    creature_1.should receive(:act).with([creature_1]).never
    creature_2.should receive(:act).with([creature_1])
    creature_2.should receive(:act).with([creature_2]).never
    subject.interact
  end
  
  it "should have all EnvironmentalFactors act on environment" do
    gravity_1 = Gravity.new
    gravity_2 = Gravity.new
    subject << gravity_1 << gravity_2
    gravity_1.should receive(:act).with(subject)
    gravity_2.should receive(:act).with(subject)
    subject.interact
  end
  
  it "should remove objects that throw exceptions on update"
  
  it "should have no area of interest by default"
  
  it "should update all game objects if no area of interest is defined"
  
  it "should not move an object outside its area of interest"
  it "should move an object inside its area of interest"
  it "should not have other objects act on an object outside its area of interest"
  it "should have other objects act on an object inside its area of interest"
  it "should not have environmental factors act on an object outside its area of interest"
  it "should have environmental factors act on an object inside its area of interest"
  it "should not allow an object outside its area of interest to act on others"
  it "should allow an object inside its area of interest to act on others"
  
  it "should update multiple areas of interest"
  
end


RSpec.describe Behavior do
  
  subject do
    Behavior.new
  end

  describe "#perform" do

    before(:each) do
      @condition = TagCondition.new("foo")
      @action = TagAction.new("bar")
      subject << @action << @condition
      @actor = Creature.new
      @target = Creature.new
    end

    it "should start and perform all Actions when all Conditions are true" do
      @action.should receive(:start).with(@actor, [@target])
      @action.should receive(:do).with(@actor, [@target])
      @target.tags << "foo"
      subject.perform(@actor, [@target])
    end
  
    it "should not call Actions unless all Conditions are true" do
      @action.should receive(:start).never
      @action.should receive(:do).never
      subject.perform(@actor, [@target])
    end
  
    it "should not start Actions that are already started" do
      @target.tags << "foo"
      subject.perform(@actor, [@target])
      @action.should receive(:start).never
      @action.should receive(:do)
      subject.perform(@actor, [@target])
    end
  
    it "should not stop Actions that aren't started" do
      @action.should receive(:start).never
      @action.should receive(:do).never
      @action.should receive(:stop).never
      subject.perform(@actor, [@target])
    end
  
    it "should call all Actions when there are no Conditions" do
      subject.remove_condition(@condition)
      @action.should receive(:start).with(@actor, [@target])
      @action.should receive(:do).with(@actor, [@target])
      subject.perform(@actor, [@target])
    end
    
  end
  
  describe "#copy" do
    
    it "should copy Actions when copying self" do
      subject << TagAction.new << TagAction.new
      subject.actions.each do |action|
        subject.copy.actions.should include(action) #Equal...
        subject.copy.actions.should_not satisfy do |actions|
          actions.any?{|a| a.equal?(action)} #...but not identical.
        end
      end
    end
    
  end
  
end


RSpec.describe GameObject do

  describe "#size" do
    subject do
      GameObject.new
    end
    it "should use size of zero when assigned size of less than zero" do
      subject.size = -1
      subject.size.should == 0
    end
  end
  
  describe "#copy" do
    subject do
      GameObject.new
    end
    it "should copy Vector when copying self" do
      subject.copy.vector.should_not equal(subject.vector)
    end
    it "should share Vector attributes with copy" do
      subject.vector = Vector.new(1, 1)
      subject.copy.vector.x.should == subject.vector.x
      subject.copy.vector.y.should == subject.vector.y
    end
    it "should copy Location when copying self" do
      subject.copy.location.should_not equal(subject.location)
    end
    it "should share Location attributes with copy" do
      subject.location = Location.new(1, 1)
      subject.copy.location.x.should == subject.location.x
      subject.copy.location.y.should == subject.location.y
    end
    it "should copy Color when copying self" do
      subject.copy.color.should_not equal(subject.color)
    end
    it "should share Color attributes with copy" do
      subject.color = Color.new(1, 1, 1)
      subject.copy.color.red.should == subject.color.red
      subject.copy.color.green.should == subject.color.green
      subject.copy.color.blue.should == subject.color.blue
    end
    it "should copy Tags when copying self" do
      subject.copy.tags.should_not equal(subject.tags)
    end
    it "should share Tags attributes with copy" do
      subject.tags = ["1", "2"]
      subject.copy.tags[0].should == subject.tags[0]
      subject.copy.tags[1].should == subject.tags[1]
    end
  end
  
  describe "defaults" do
    subject do
      GameObject.new
    end
    it "has a default Location of 0, 0" do
      subject.location.should == Location.new(0, 0)
    end
    it "has a default Color of white" do
      subject.color.should == Color.white
    end
    it "has a default speed of 0" do
      subject.vector.speed.should == 0
    end
    it "has a default pitch of 0" do
      subject.vector.pitch.should == 0
    end
    it "has a default name of nil" do
      subject.name.should == nil
    end
    it "has a default size of 1" do
      subject.size.should == 1
    end
    it "has no tags by default" do
      subject.tags.should be_empty
    end
    it "has a unique identifier by default" do
      subject.identifier.should_not == GameObject.new.identifier
    end
  end
  
  describe "#new" do
    it "takes a :name key" do
      GameObject.new(:name => "foo").name.should == "foo"
    end
    it "takes a :location key" do
      GameObject.new(:location => Location.new(1, 1)).location.should == Location.new(1, 1)
    end
    it "takes a :color key" do
      GameObject.new(:color => Color.blue).color.should == Color.blue
    end
    it "takes an :age key" do
      GameObject.new(:age => 100).age.should be_within(MARGIN).of(100)
    end
    it "takes a :size key" do
      GameObject.new(:size => 3).size.should == 3
    end
    it "takes a :tags key" do
      GameObject.new(:tags => ["blue team"]).tags.should == ["blue team"]
    end
  end
  
  it "has no default shape"
  
  it "should pass calls to collided method on to its Shape object"

end


RSpec.describe Creature do
  
  describe "#new" do
  
    subject do
      Creature.new
    end
  
    it "has no behaviors by default" do
      subject.behavior_count.should == 0
    end
    
  end
  
  describe "#copy" do
  
    it "should copy Behaviors when copying self" do
      subject << Behavior.new << Behavior.new
      subject.behaviors.each do |behavior|
        subject.copy.behaviors.should include(behavior) #Equal...
        subject.copy.behaviors.should_not satisfy {|behaviors| behaviors.any?{|b| b.equal?(behavior)}} #...but not identical.
      end
    end
  
  end
  
  it "takes a :behaviors key in its constructor" do
    Creature.new(:behaviors => [Behavior.new]).behaviors.should include(Behavior.new)
  end
  
  it "should have no area of interest by default"
  it "should act on all objects if no area of interest is defined"
  it "should not act on an object outside its area of interest"
  it "should act on all objects inside its area of interest"
  it "should allow multiple areas of interest"
  
end


RSpec.describe AreaOfInterest do

  it "should report all GameObjects whose Locations are within its bounds"
  it "should filter out all GameObjects whose Locations are not within its bounds"
  it "should have a default evaluation frequency of 1"
  it "should always report objects if its evaluation frequency is 1"
  it "should report objects every other update if its evaluation frequency is 2"
  it "should report objects every three updates if its evaluation frequency is 3"

end


RSpec.describe Color do
  
  describe "#{new}" do
    
    subject do
      Color.new(0.5, 0.5, 0.5)
    end
    
    it "accepts red, green, and blue values for contructor" do 
      subject.red.should == 0.5
      subject.green.should == 0.5
      subject.blue.should == 0.5
    end
    
  end
  
  describe "red, green, and blue" do
    
    subject do
      Color.new
    end
    
    it "has a default color of white" do
      subject.red.should == 1.0
      subject.green.should == 1.0
      subject.blue.should == 1.0
    end

    it "constrains values between 0 and 1" do
      subject.red += 2
      subject.green += 2
      subject.blue += 2
      subject.red.should == 1.0
      subject.green.should == 1.0
      subject.blue.should == 1.0
      subject.red -= 3
      subject.green -= 3
      subject.blue -= 3
      subject.red.should == 0.0
      subject.green.should == 0.0
      subject.blue.should == 0.0
    end
    
  end
  
  
end


RSpec.describe Vector do
  
  describe "speed and pitch" do
    
    subject do
      Vector.new
    end

    it "defaults to zero" do
      subject.speed.should == 0.0
      subject.pitch.should == 0.0
      subject.x.should == 0.0
      subject.y.should == 0.0
    end
    
  end
  
  describe "x and y" do
    
    subject do
      Vector.new
    end

    it "derives x and y when speed and angle are set" do
      subject.speed = 1.4142
      subject.pitch = 45
      subject.x.should be_within(MARGIN).of(1)
      subject.y.should be_within(MARGIN).of(1)
      
      subject.speed = 1.4142
      subject.pitch = 135
      subject.x.should be_within(MARGIN).of(-1)
      subject.y.should be_within(MARGIN).of(1)
      
      subject.speed = 1.4142
      subject.pitch = 225
      subject.x.should be_within(MARGIN).of(-1)
      subject.y.should be_within(MARGIN).of(-1)
      
      subject.speed = 1.4142
      subject.pitch = 315
      subject.x.should be_within(MARGIN).of(1)
      subject.y.should be_within(MARGIN).of(-1)
      
      subject.speed = 4
      subject.pitch = 150
      subject.x.should be_within(MARGIN).of(-3.464)
      subject.y.should be_within(MARGIN).of(2)
      
      subject.speed = 5
      subject.pitch = 53.13
      subject.x.should be_within(MARGIN).of(3)
      subject.y.should be_within(MARGIN).of(4)
      
      subject.speed = 5
      subject.pitch = 233.13
      subject.x.should be_within(MARGIN).of(-3)
      subject.y.should be_within(MARGIN).of(-4)
      
      subject.speed = 5
      subject.pitch = 306.87
      subject.x.should be_within(MARGIN).of(3)
      subject.y.should be_within(MARGIN).of(-4)
      
    end
    
    it "wraps angles over 360 around to 0" do
      subject.speed = 5
      subject.pitch = 413.13 #360 + 53.13
      subject.x.should be_within(MARGIN).of(3)
      subject.y.should be_within(MARGIN).of(4)
    end
    
    it "converts negative angles to positive equivalents" do
      subject.speed = 5
      subject.pitch = -53.13 #360 - 53.13 = 306.87
      subject.x.should be_within(MARGIN).of(3)
      subject.y.should be_within(MARGIN).of(-4)
    end
    
  end
  
  describe "#+" do
    
    it "adds vectors' speeds together if they have the same pitch" do
      vector = Vector.new(1, 45) + Vector.new(1, 45)
      vector.speed.should be_within(MARGIN).of(2)
    end
    
    it "keeps the same pitch if added vectors' pitches are identical" do
      vector = Vector.new(1, 45) + Vector.new(1, 45)
      vector.pitch.should be_within(MARGIN).of(45)
    end
    
    it "cancels out vectors of opposite angles" do
      vector = Vector.new(2, 0) + Vector.new(1, 180)
      vector.speed.should be_within(MARGIN).of(1)
      vector.pitch.should be_within(MARGIN).of(0)
      vector = Vector.new(2, 45) + Vector.new(1, 225)
      vector.speed.should be_within(MARGIN).of(1)
      vector.pitch.should be_within(MARGIN).of(45)
      vector = Vector.new(2, 135) + Vector.new(1, 315)
      vector.speed.should be_within(MARGIN).of(1)
      vector.pitch.should be_within(MARGIN).of(135)
      vector = Vector.new(2, 225) + Vector.new(1, 45)
      vector.speed.should be_within(MARGIN).of(1)
      vector.pitch.should be_within(MARGIN).of(225)
      vector = Vector.new(2, 315) + Vector.new(1, 135)
      vector.speed.should be_within(MARGIN).of(1)
      vector.pitch.should be_within(MARGIN).of(315)
    end
    
  end
  
end


RSpec.describe Utility do
  
  describe "#to_radians" do
    it "converts degrees to radians" do
      Utility.to_radians(0).should be_within(MARGIN).of(0)
      Utility.to_radians(180).should be_within(MARGIN).of(Math::PI)
      Utility.to_radians(359).should be_within(0.1).of(Math::PI * 2)
    end
  end
  
  describe "#to_degrees" do
    it "converts radians to degrees" do
      Utility.to_degrees(0).should be_within(MARGIN).of(0)
      Utility.to_degrees(Math::PI).should be_within(MARGIN).of(180)
      Utility.to_degrees(Math::PI * 2 - 0.0001).should be_within(1).of(359)
    end
  end
  
  describe "#find_angle" do
    it "finds the angle between two Locations" do
      origin = Location.new(0, 0)
      Utility.find_angle(origin, Location.new(1, 0)).should be_within(MARGIN).of(0)
      Utility.find_angle(origin, Location.new(0, 1)).should be_within(MARGIN).of(90)
      Utility.find_angle(origin, Location.new(1, 1)).should be_within(MARGIN).of(45)
      Utility.find_angle(origin, Location.new(-1, 1)).should be_within(MARGIN).of(135)
      Utility.find_angle(origin, Location.new(-1, -1)).should be_within(MARGIN).of(225)
      Utility.find_angle(origin, Location.new(1, -1)).should be_within(MARGIN).of(315)
    end
  end
  
  describe "#find_distance" do
    it "finds the distance between two Locations" do
      origin = Location.new(0, 0)
      Utility.find_distance(origin, Location.new(1, 0)).should be_within(MARGIN).of(1)
      Utility.find_distance(origin, Location.new(0, 1)).should be_within(MARGIN).of(1)
      Utility.find_distance(origin, Location.new(1, 1)).should be_within(MARGIN).of(1.4142)
      Utility.find_distance(origin, Location.new(-1, 1)).should be_within(MARGIN).of(1.4142)
      Utility.find_distance(origin, Location.new(-1, -1)).should be_within(MARGIN).of(1.4142)
      Utility.find_distance(origin, Location.new(1, -1)).should be_within(MARGIN).of(1.4142)
    end
  end
  
  describe "#find_reflection_angle" do
    it "finds the angle of reflection, given a normal and the angle of incidence" do
      Utility.find_reflection_angle(0, 150).should be_within(MARGIN).of(210)
      Utility.find_reflection_angle(0, 30).should be_within(MARGIN).of(330)
      Utility.find_reflection_angle(90, 30).should be_within(MARGIN).of(150)
      Utility.find_reflection_angle(90, 330).should be_within(MARGIN).of(210)
      Utility.find_reflection_angle(180, 330).should be_within(MARGIN).of(30)
      Utility.find_reflection_angle(180, 210).should be_within(MARGIN).of(150)
      Utility.find_reflection_angle(270, 210).should be_within(MARGIN).of(330)
      Utility.find_reflection_angle(270, 150).should be_within(MARGIN).of(30)
    end
  end
  
  describe "#collided" do
    describe "separated objects" do
      it "does not report a collision" do
        Utility.collided?(
          GameObject.new(:location => Location.new(0, 0), :size => 0.196), #Radius = 0.25
          GameObject.new(:location => Location.new(1, 0), :size => 0.196)
        ).should be_falsey
      end
    end
    describe "touching objects" do
      it "does not report a collision" do
        Utility.collided?(
          GameObject.new(:location => Location.new(0, 0), :size => 0.785), #Radius = 0.5
          GameObject.new(:location => Location.new(1, 0), :size => 0.785)
        ).should be_falsey
      end
    end
    describe "collided objects" do
      it "reports a collision" do
        Utility.collided?(
          GameObject.new(:location => Location.new(0, 0), :size => 1.766), #Radius = 0.75
          GameObject.new(:location => Location.new(1, 0), :size => 1.766)
        ).should be_truthy
      end
    end
    describe "objects in same place" do
      it "reports a collision" do
        Utility.collided?(
          GameObject.new(:location => Location.new(0, 0)),
          GameObject.new(:location => Location.new(0, 0))
        ).should be_truthy
      end
    end
  end
  
end
