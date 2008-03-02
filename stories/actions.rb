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


require 'spec/story'
require 'zyps'
require 'zyps/actions'

include Zyps

class Clock
	def elapsed_time; @@elapsed_time; end
	def Clock.elapsed_time=(value); @@elapsed_time = value; end
end

# 		Given a creature at 0, 0
# 		And a target at 1, 1
# 		And an approach action with a rate of 1
# 		When 0.1 seconds elapse
# 		Then the creature's speed should be 0.1
# 		And the creature's angle should be 45
steps_for(:actions) do
	Given "an environment" do
		@environment = Environment.new
	end
	Given "a creature at $x, $y" do |x, y|
		@creature = Creature.new(:location => Location.new(x.to_f, y.to_f))
		@environment << @creature
	end
	Given "a target at $x, $y" do |x, y|
		@target = Creature.new(:location => Location.new(x.to_f, y.to_f))
		@environment << @target
	end
	Given "an approach action with a rate of $rate" do |rate|
		@creature.add_behavior Behavior.new(
			:actions => [ApproachAction.new(rate.to_f)]
		)
	end
	When "$seconds seconds elapse" do |seconds|
		Clock.elapsed_time = seconds.to_f
		@environment.interact
	end
	Then "the creature's speed should be $speed" do |speed|
		@creature.vector.speed.should == speed.to_f
	end
	Then /the creature's (angle|pitch) should be ([\d\.]+)/ do |attribute, pitch|
		@creature.vector.pitch.should == pitch.to_f
	end
end

with_steps_for :actions do
	run File.expand_path(__FILE__).sub(/.rb$/, ".txt")
end
