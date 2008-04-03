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
	
	it "should remove objects that throw exceptions on update"
	
end
