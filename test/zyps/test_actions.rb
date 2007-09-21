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


	#Create and populate an environment.
	def setup
		@actor = Creature.new('name', Location.new(0, 0))
		@target1 = GameObject.new('name', Location.new(1, 1))
		@target2 = GameObject.new('name', Location.new(-2, -2))
		#Create an environment, and add the objects.
		@environment = Environment.new
		#Order is important - we want to act on target 1 first.
		@environment.objects << @actor << @target1 << @target2
	end
	
	#Add a new behavior to a creature with the given action.
	def add_action(action, creature)
		behavior = Behavior.new
		behavior.actions << action
		creature.behaviors << behavior
	end


	#A FaceAction turns directly toward the target.
	def test_face_action
		add_action(FaceAction.new, @actor)
		@environment.interact
		assert_equal(45, @actor.vector.pitch)
	end
	
	
	#An AccelerateAction speeds up the actor at a given rate.
	def test_accelerate_action
		#Accelerate 1 unit per second.
		add_action(AccelerateAction.new(1), @actor)
		@environment.interact
		#Clock always returns 0.1 seconds, so actor should be moving 0.1 unit/second faster.
		assert_equal(0.1, @actor.vector.speed)
	end
	
	
	#A TurnAction turns the actor at a given rate.
	def test_turn_action
		#Turn 1 degree per second.
		add_action(TurnAction.new(1), @actor)
		@environment.interact
		#Clock always returns 0.1 seconds, so actor should be turned 0.1 degrees.
		assert_equal(0.1, @actor.vector.pitch)
	end
	
	
	#An ApproachAction pushes the actor toward the target.
	def test_approach_action
	
		#Create an ApproachAction with a 0-degree vector, turn rate of 40 degrees/sec.
		@actor.vector = Vector.new(0, 0)
		action = ApproachAction.new(Vector.new(1, 0), 40)
		add_action(action, @actor)
		#Act.
		@environment.interact
		#Ensure action's thrust vector is correct for 0.1 seconds.
		assert_equal(1.0, action.heading.speed)
		assert_equal(4.0, action.heading.pitch)
		#Ensure actor's resulting vector is correct.
		assert_in_delta(0.997, @actor.vector.x, 0.001)
		assert_in_delta(0.069, @actor.vector.y, 0.001)

	end
	
	#Ensure ApproachAction doesn't oversteer.
	def test_approach_action_accuracy
	
		#Create an ApproachAction with a 0-degree vector, turn rate high enough to turn more than 45 degrees in 0.1 seconds.
		#Action should only turn as far as target.
		@actor.vector = Vector.new(0, 0)
		action = ApproachAction.new(Vector.new(1, 0), 500)
		add_action(action, @actor)
		#Act.
		@environment.interact

		#Ensure actor is approaching target directly.
		assert_equal(1.0, action.heading.speed)
		assert_equal(45, action.heading.pitch)
		#Ensure actor's resulting vector is correct.
		assert_in_delta(0.707, @actor.vector.x, 0.001)
		assert_in_delta(0.707, @actor.vector.y, 0.001)
		
	end
	
	
	#A FleeAction pushes the actor away from a target.
	def test_flee_action

		#Create a FleeAction with a 0-degree vector, turn rate of 40 degrees/sec.
		@actor.vector = Vector.new(0, 0)
		action = FleeAction.new(Vector.new(1, 0), 40)
		add_action(action, @actor)
		#Act.
		@environment.interact
		#Ensure action's thrust vector is correct for 0.1 seconds.
		assert_equal(1.0, action.heading.speed)
		assert_equal(356.0, action.heading.pitch) #Should be heading away.
		#Ensure actor's resulting vector is correct.
		assert_in_delta(0.997, @actor.vector.x, 0.001)
		assert_in_delta(-0.069, @actor.vector.y, 0.001)
	end
	
	#Ensure flee action doesn't oversteer.
	def test_flee_action_accuracy
	
		#Create a FleeAction with a 0-degree vector, turn rate high enough to turn more than 135 degrees in 0.1 seconds.
		#Action should turn directly away from target, but no farther.
		@actor.vector = Vector.new(0, 0)
		action = FleeAction.new(Vector.new(1, 0), 1400)
		add_action(action, @actor)
		#Act.
		@environment.interact
		#Ensure actor is fleeing directly away from target.
		assert_equal(1.0, action.heading.speed)
		assert_equal(225, action.heading.pitch)
		#Ensure actor's resulting vector is correct.
		assert_in_delta(-0.707, @actor.vector.x, 0.001)
		assert_in_delta(-0.707, @actor.vector.y, 0.001)
		
	end
	
	
	#A DestroyAction removes the target from the environment.
	def test_destroy_action
		#Create a DestroyAction, linked to the environment.
		add_action(DestroyAction.new(@environment), @actor)
		#Act.
		@environment.interact
		#Verify target is removed from environment.
		assert(! @environment.objects.include?(@target1))
		#Verify non-target is removed from environment.
		assert(@environment.objects.include?(@target2))
		#Act again.
		@environment.interact
		#Verify targets were switched.
		assert(! @environment.objects.include?(@target2), "Targets should have been switched.")
	end
	
	
	#An EatAction is like a DestroyAction, but also makes the actor grow in size.
	def test_eat_action
		#Create an EatAction, linked to the environment.
		add_action(EatAction.new(@environment), @actor)
		#Act.
		@actor.size = 1
		@target1.size = 1
		@environment.interact
		#Verify target is removed from environment.
		assert(! @environment.objects.include?(@target1))
		#Verify creature has grown by the appropriate amount.
		assert_equal(2, @actor.size)
	end
	
	
	#A TagAction adds a tag to the target.
	def test_tag_action
		#Create a TagAction, and act.
		add_action(TagAction.new("tag"), @actor)
		@environment.interact
		#Verify target has appropriate tag.
		assert(@target1.tags.include?("tag"))
	end
	
	
	#A BlendAction shifts the target's color toward the given color.
	def test_blend_action_black
		#Create a BlendAction that blends to black.
		add_action(BlendAction.new(Color.new(0, 0, 0)), @actor)
		#Set the target's color.
		@target1.color = Color.new(0.5, 0.5, 0.5)
		#Act.
		@environment.interact
		#Verify the target's new color.
		assert_equal(0.25, @target1.color.red)
		assert_equal(0.25, @target1.color.green)
		assert_equal(0.25, @target1.color.blue)
	end
		
	#Test shifting colors toward white.
	def test_blend_action_white
		#Create a BlendAction that blends to white.
		add_action(BlendAction.new(Color.new(1, 1, 1)), @actor)
		#Set the target's color.
		@target1.color = Color.new(0.5, 0.5, 0.5)
		#Act.
		@environment.interact
		#Verify the target's new color.
		assert_equal(0.75, @target1.color.red)
		assert_equal(0.75, @target1.color.green)
		assert_equal(0.75, @target1.color.blue)
	end
	
	
	#A PushAction pushes the target away.
	def test_push_action
		#Create a PushAction, and act.
		add_action(PushAction.new(1), @actor)
		@environment.interact
		#Verify target's speed and direction are correct.
		assert_equal(0.1, @target1.vector.speed, "@target1 should have been pushed away from @actor.")
		assert_equal(45.0, @target1.vector.pitch, "@target1's angle should be facing away from @actor.")
	end

	
	#A PullAction pulls the target toward the actor.
	def test_pull_action
		#Create a PullAction, and act.
		add_action(PullAction.new(1), @actor)
		@environment.interact
		#Verify target's speed and direction are correct.
		assert_equal(0.1, @target1.vector.speed, "@target1 should have been pulled toward @actor.")
		assert_equal(225.0, @target1.vector.pitch, "@target1's angle should be facing toward @actor.")
	end
	
end
