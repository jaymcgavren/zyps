# Copyright 2007-2008 Zyps Contributors.
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

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

gems_loaded = false
begin
	require 'spec'
	require 'zyps'
	require 'zyps/actions'
rescue LoadError
	if gems_loaded == false
		require 'rubygems'
		gems_loaded = true
		retry
	else
		raise
	end
end


include Zyps


shared_examples_for "spawn action" do

	before :each do
		@environment = Environment.new
		@actor = Creature.new
		@target = GameObject.new
		@environment << @actor << @target
	end

	it "spawns prototype object into target's environment" do
		@action.prototypes = [GameObject.new(:name => 'foo')]
		@action.do(@actor, [@target])
		@target.environment.should satisfy {|e| e.objects.any?{|o| o.name == 'Copy of foo'}}
	end
		
	it "child's starting location should match actor's" do
	  @action.prototypes = [Creature.new(:name => 'foo')]
	  @actor.location = Location.new(2, 2)
	  @action.do(@actor, [@target])
	  child = @target.environment.objects.find{|o| o.name == 'Copy of foo'}
	  child.location.x.should == 2.0
	  child.location.y.should == 2.0
	end
	
	it "child should be copy of prototype, not the same object" do
	  @action.prototypes = [Creature.new(:name => 'foo')]
	  @action.do(@actor, [@target])
	  @target.environment.objects.should_not include @action.prototypes.first
		@target.environment.should_not satisfy {|e| e.objects.any?{|o| o.equal?(@action.prototypes.first)}}
		@target.environment.should satisfy {|e| e.objects.any?{|o| o.name == 'Copy of foo'}}
	end
	
end


describe ShootAction do

	before :each do
		@action = ShootAction.new
	end

	it_should_behave_like "spawn action"

	it "can spawn groups of objects at a time" do
		@action.prototypes = [[GameObject.new(:name => 'foo'), GameObject.new(:name => 'bar')]]
		@action.do(@actor, [@target])
		@target.environment.should satisfy {|e| e.objects.any?{|o| o.name == 'Copy of foo'}}
		@target.environment.should satisfy {|e| e.objects.any?{|o| o.name == 'Copy of bar'}}
	end
	
	it "spawns one group at a time" do
		@action.prototypes = [[GameObject.new(:name => 'foo'), GameObject.new(:name => 'bar')], GameObject.new(:name => 'baz')]
		@action.do(@actor, [@target])
		@target.environment.should satisfy {|e| e.objects.any?{|o| o.name == 'Copy of foo'}}
		@target.environment.should satisfy {|e| e.objects.any?{|o| o.name == 'Copy of bar'}}
		@target.environment.should_not satisfy {|e| e.objects.any?{|o| o.name == 'Copy of baz'}}
		#Spawn second group.
		@action.do(@actor, [@target])
		@target.environment.should satisfy {|e| e.objects.any?{|o| o.name == 'Copy of baz'}}
	end
	
end


describe ExplodeAction do
  
  before :each do
    @action = ExplodeAction.new
  end
  
  it_should_behave_like "spawn action"
  
  it "should remove the actor from the environment" do
    @action.do(@actor, [@target])
    @target.environment.objects.should_not include(@actor)
  end
  
  it "should add actor's vector to prototypes" do
		@action.prototypes = [
		  Creature.new(:name => 'creature', :vector => Vector.new(3.0, 45.0)),
		  GameObject.new(:name => 'object', :vector => Vector.new(5.0, 45.0))
		]
		@actor.vector = Vector.new(1.0, 45.0)
		@action.do(@actor, [@target])
		creature_vector = @target.environment.objects.find{|o| o.name == 'Copy of creature'}.vector
		creature_vector.pitch.should be_close(45, 0.01)
		creature_vector.speed.should be_close(4, 0.01)
		object_vector = @target.environment.objects.find{|o| o.name == 'Copy of object'}.vector
		object_vector.pitch.should be_close(45, 0.01)
		object_vector.speed.should be_close(6, 0.01)
  end
  
end
