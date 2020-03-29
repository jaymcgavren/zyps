require "spec_helper"



include Zyps


RSpec.shared_examples_for "spawn action" do

  before :each do
    @environment = Environment.new
    @actor = Creature.new
    @target = GameObject.new
    @environment << @actor << @target
  end

  it "spawns prototype object into target's environment" do
    subject.prototypes = [GameObject.new(:name => 'foo')]
    subject.do(@actor, [@target])
    @target.environment.should satisfy {|e| e.objects.any?{|o| o.name == 'Copy of foo'}}
  end
    
  it "child's starting location should match actor's" do
    subject.prototypes = [Creature.new(:name => 'foo')]
    @actor.location = Location.new(2, 2)
    subject.do(@actor, [@target])
    child = @target.environment.objects.find{|o| o.name == 'Copy of foo'}
    child.location.x.should == 2.0
    child.location.y.should == 2.0
  end
  
  it "child should be copy of prototype, not the same object" do
    subject.prototypes = [Creature.new(:name => 'foo')]
    subject.do(@actor, [@target])
    @target.environment.objects.should_not include subject.prototypes.first
    @target.environment.should_not satisfy {|e| e.objects.any?{|o| o.equal?(subject.prototypes.first)}}
    @target.environment.should satisfy {|e| e.objects.any?{|o| o.name == 'Copy of foo'}}
  end
  
end


RSpec.describe ShootAction do

  subject do
    ShootAction.new
  end

  before :each do
    @environment = Environment.new
    @actor = Creature.new
    @target = GameObject.new
    @environment << @actor << @target
  end

  it_should_behave_like "spawn action"

  it "can spawn groups of objects at a time" do
    subject.prototypes = [[GameObject.new(:name => 'foo'), GameObject.new(:name => 'bar')]]
    subject.do(@actor, [@target])
    @target.environment.should satisfy {|e| e.objects.any?{|o| o.name == 'Copy of foo'}}
    @target.environment.should satisfy {|e| e.objects.any?{|o| o.name == 'Copy of bar'}}
  end
  
  it "spawns one group at a time" do
    subject.prototypes = [[GameObject.new(:name => 'foo'), GameObject.new(:name => 'bar')], GameObject.new(:name => 'baz')]
    subject.do(@actor, [@target])
    @target.environment.should satisfy {|e| e.objects.any?{|o| o.name == 'Copy of foo'}}
    @target.environment.should satisfy {|e| e.objects.any?{|o| o.name == 'Copy of bar'}}
    @target.environment.should_not satisfy {|e| e.objects.any?{|o| o.name == 'Copy of baz'}}
    #Spawn second group.
    subject.do(@actor, [@target])
    @target.environment.should satisfy {|e| e.objects.any?{|o| o.name == 'Copy of baz'}}
  end
  
end


RSpec.describe ExplodeAction do
  
  subject do
    ExplodeAction.new
  end
  
  before :each do
    @environment = Environment.new
    @actor = Creature.new
    @target = GameObject.new
    @environment << @actor << @target
  end
  
  it_should_behave_like "spawn action"
  
  it "should remove the actor from the environment" do
    subject.do(@actor, [@target])
    @target.environment.objects.should_not include(@actor)
  end
  
  it "should add actor's vector to prototypes" do
    subject.prototypes = [
      Creature.new(:name => 'creature', :vector => Vector.new(3.0, 45.0)),
      GameObject.new(:name => 'object', :vector => Vector.new(5.0, 45.0))
    ]
    @actor.vector = Vector.new(1.0, 45.0)
    subject.do(@actor, [@target])
    creature_vector = @target.environment.objects.find{|o| o.name == 'Copy of creature'}.vector
    creature_vector.pitch.should be_within(MARGIN).of(45)
    creature_vector.speed.should be_within(MARGIN).of(4)
    object_vector = @target.environment.objects.find{|o| o.name == 'Copy of object'}.vector
    object_vector.pitch.should be_within(MARGIN).of(45)
    object_vector.speed.should be_within(MARGIN).of(6)
  end
  
end
