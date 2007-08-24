# Copyright 2007 Jay McGavren, jay@mcgavren.com.
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


require 'zyps'
require 'zyps/actions'
require 'test/unit'


#Redefine Clock to return a predictable time.
class Clock
	def elapsed_time; 0.1; end
end


class TestActions < Test::Unit::TestCase


	def setup
		@actor = Creature.new('name', Location.new(0, 0))
		@target = GameObject.new('name', Location.new(1, 1))
	end


	def test_face_action
		FaceAction.new.do(@actor, @target)
		assert_equal(45, @actor.vector.pitch)
	end
	
	
	def test_accelerate_action
		#Accelerate 1 unit per second.
		AccelerateAction.new(1).do(@actor, @target)
		#Clock always returns 0.1 seconds, so actor should be moving 0.1 unit/second faster.
		assert_equal(0.1, @actor.vector.speed)
	end
	
	
	def test_turn_action
		#Turn 1 degree per second.
		TurnAction.new(1).do(@actor, @target)
		#Clock always returns 0.1 seconds, so actor should be turned 0.1 degrees.
		assert_equal(0.1, @actor.vector.pitch)
	end
	
	
	def test_approach_action
		#TODO
	end
	
	
	def test_flee_action
		#TODO
	end
	
	
	def test_destroy_action
		#Create an environment, and add the objects.
		environment = Environment.new
		environment.objects << @actor << @target
		#Create a DestroyAction, linked to the environment.
		action = DestroyAction.new(environment)
		#Act.
		action.do(@actor, @target)
		#Verify target is removed from environment.
		assert(! environment.objects.include?(@target))
	end
	
	
	def test_eat_action
		#Create an environment, and add the objects.
		environment = Environment.new
		environment.objects << @actor << @target
		#Create an EatAction, linked to the environment.
		action = EatAction.new(environment)
		#Act.
		@actor.size = 1
		@target.size = 1
		action.do(@actor, @target)
		#Verify target is removed from environment.
		assert(! environment.objects.include?(@target))
		#Verify creature has grown by the appropriate amount.
		assert_equal(2, @actor.size)
	end
	
	
	def test_tag_action
		#Create a TagAction, and act.
		TagAction.new("tag").do(@actor, @target)
		#Verify target has appropriate tag.
		assert(@target.tags.include?("tag"))
	end
	
	
	def test_blend_action
		#Create a BlendAction that blends to black.
		action = BlendAction.new(Color.new(0, 0, 0))
		#Set the target's color.
		@target.color = Color.new(0.5, 0.5, 0.5)
		#Act.
		action.do(@actor, @target)
		#Verify the target's new color.
		assert_equal(0.25, @target.color.red)
		assert_equal(0.25, @target.color.green)
		assert_equal(0.25, @target.color.blue)
		#Create a BlendAction that blends to white.
		action = BlendAction.new(Color.new(1, 1, 1))
		#Set the target's color.
		@target.color = Color.new(0.5, 0.5, 0.5)
		#Act.
		action.do(@actor, @target)
		#Verify the target's new color.
		assert_equal(0.75, @target.color.red)
		assert_equal(0.75, @target.color.green)
		assert_equal(0.75, @target.color.blue)
	end
	
	
end
