# Copyright 2007-2008 Jay McGavren, jay@mcgavren.com.
# 
# This file is part of Zyps.
# 
# Zyps is free software; you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


require 'spec'
require 'zyps'
require 'zyps/actions'
require 'zyps/conditions'
require 'zyps/environmental_factors'


include Zyps


describe Environment do

	before(:each) do
		@environment = Environment.new
	end
	
	it "should accept GameObjects" do
		@environment << GameObject.new << GameObject.new
		@environment.object_count.should equal(2) #Can't use have(); doesn't return array.
	end
	
	it "should accept Creatures" do
		@environment << Creature.new << Creature.new
		@environment.object_count.should equal(2) #Can't use have(); doesn't return array.
	end
	
	it "should accept EnvironmentalFactors" do
		@environment << Gravity.new << Gravity.new
		@environment.environmental_factor_count.should == 2 #Can't use have(); doesn't return array.
	end
	

	it "should allow copies" do
		copy = @environment.copy
		copy.should == @environment
	end

	it "should clone attributes when copying"
	
	it "should move all objects on update" do
		object = GameObject.new(:vector => Vector.new(1, 0))
		@environment << object
		clock = Clock.new
		clock.should_receive(:elapsed_time).and_return(1)
		@environment.clock = clock
		@environment.interact
		object.location.should == Location.new(1, 0)
	end
	
	it "should have all objects act on each other" do
		creature_1 = Creature.new
		creature_2 = Creature.new
		@environment << creature_1 << creature_2
		creature_1.should_receive(:act).with([creature_2])
		creature_1.should_not_receive(:act).with([creature_1])
		creature_2.should_receive(:act).with([creature_1])
		creature_2.should_not_receive(:act).with([creature_2])
		@environment.interact
	end
	
	it "should have all EnvironmentalFactors act on environment" do
		gravity_1 = Gravity.new
		gravity_2 = Gravity.new
		@environment << gravity_1 << gravity_2
		gravity_1.should_receive(:act).with(@environment)
		gravity_2.should_receive(:act).with(@environment)
		@environment.interact
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


describe Behavior do

	before(:each) do
		@behavior = Behavior.new
		@condition = TagCondition.new("foo")
		@action = TagAction.new("bar")
		@behavior << @action << @condition
		@actor = Creature.new
		@target = Creature.new
	end

	it "should start and perform all Actions when all Conditions are true" do
		@action.should_receive(:start).with(@actor, [@target])
		@action.should_receive(:do).with(@actor, [@target])
		@target.tags << "foo"
		@behavior.perform(@actor, [@target])
	end
	
	it "should not call Actions unless all Conditions are true" do
		@action.should_not_receive(:start)
		@action.should_not_receive(:do)
		@behavior.perform(@actor, [@target])
	end
	
	it "should not start Actions that are already started" do
		@target.tags << "foo"
		@behavior.perform(@actor, [@target])
		@action.should_not_receive(:start)
		@action.should_receive(:do)
		@behavior.perform(@actor, [@target])
	end
	
	it "should not stop Actions that aren't started" do
		@action.should_not_receive(:start)
		@action.should_not_receive(:do)
		@action.should_not_receive(:stop)
		@behavior.perform(@actor, [@target])
	end
	
	it "should call all Actions when there are no Conditions" do
		@behavior.remove_condition(@condition)
		@action.should_receive(:start).with(@actor, [@target])
		@action.should_receive(:do).with(@actor, [@target])
		@behavior.perform(@actor, [@target])
	end

end


describe GameObject do

	before(:each) do
		@object = GameObject.new
	end

	it "has no default shape" do
		@object.shape.should be_nil
	end
	
	it "should pass calls to collided method on to its Shape object"

end


describe Creature do
	
	it "should have no area of interest by default"
	it "should act on all objects if no area of interest is defined"
	it "should not act on an object outside its area of interest"
	it "should act on all objects inside its area of interest"
	it "should allow multiple areas of interest"
	
end


describe AreaOfInterest do

	it "should report all GameObjects whose Locations intersect its Shape"
	it "should filter out all GameObjects whose Locations do not intersect its Shape"
	it "should have a default evaluation frequency of 1"
	it "should always report objects if its evaluation frequency is 1"
	it "should report objects every other update if its evaluation frequency is 2"
	it "should report objects every three updates if its evaluation frequency is 3"

end
