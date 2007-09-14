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
require 'test/unit'


#Redefine Clock to return a predictable time.
class Clock
	def elapsed_time; 0.1; end
end


class TestGameObject < Test::Unit::TestCase


	def test_constraints
		#Test at initialization.
		object = GameObject.new(
			"", #Name.
			Location.new,
			Color.new,
			Vector.new,
			0,
			-1 #Size.
		)
		assert_equal(0, object.size)
		#Test accessors.
		object = GameObject.new
		object.size = -1
		assert_equal(0, object.size)
	end


	def test_move
		#Set up moving object.
		object = GameObject.new
		object.location = Location.new(0, 0)
		object.vector = Vector.new(1.4142, 45)
		#Move for 1 second.
		object.move(1)
		#Check object moved to expected coordinates.
		assert_in_delta(1, object.location.x, 0.001)
		assert_in_delta(1, object.location.y, 0.001)
	end


end


class TestCreature < Test::Unit::TestCase


	def test_default_initialization
		creature = Creature.new
		assert_not_nil(creature.identifier)
		assert_equal(0, creature.location.x)
		assert_equal(0, creature.location.y)
		assert_equal(1, creature.color.red)
		assert_equal(1, creature.color.green)
		assert_equal(1, creature.color.blue)
		assert_equal(0, creature.vector.speed)
		assert_equal(0, creature.vector.pitch)
		assert_equal(nil, creature.name)
		assert_equal(1, creature.size)
		assert_equal([], creature.tags)
		assert_equal([], creature.behaviors)
		#Identifiers should be unique.
		assert_not_equal(creature.identifier, Creature.new.identifier)
	end
	
	
	def test_explicit_initialization
		behavior = Behavior.new
		creature = Creature.new(
			"name",
			Location.new(10, -3),
			Color.new(0.5, 0.6, 0.7),
			Vector.new(1.5, 225),
			2.001, #Age.
			5.0, #Size.
			["predator", "blue team"],
			[behavior]
		)
		assert_equal("name", creature.name)
		assert_equal(10, creature.location.x)
		assert_equal(-3, creature.location.y)
		assert_equal(0.5, creature.color.red)
		assert_equal(0.6, creature.color.green)
		assert_equal(0.7, creature.color.blue)
		assert_equal(1.5, creature.vector.speed)
		assert_equal(225, creature.vector.pitch)
		assert_equal(5.0, creature.size)
		assert(creature.tags.include?("predator"))
		assert(creature.tags.include?("blue team"))
		assert(creature.behaviors.include?(behavior))
	end
	
	
end



class TestEnvironment < Test::Unit::TestCase

	
	def setup
	
		#Create an environment and add creatures.
		@environment = Environment.new
		@environment.objects << Creature.new('1')
		@environment.objects << Creature.new('2')
		@environment.objects << Creature.new('3')
		
	end
	
	
	#An action that keeps a log of the actor and target.
	class LogAction < Action
		attr_reader :interactions
		def initialize
			#Interactions will be logged here.
			@interactions = []
		end
		def do(actor, target)
			#Log the interaction.
			@interactions << "#{actor.name} targeting #{target.name}"
		end
	end
	
	def test_interactions
	
		#Set up behaviors that will log interactions.
		log = LogAction.new
		@environment.objects.each do |creature|
			behavior = Behavior.new
			behavior.actions << log
			creature.behaviors << behavior
		end
		
		#Have environment elements interact.
		@environment.interact

		#Look for expected interactions (each should only occur once).
		assert(log.interactions.find_all{|i| i == "2 targeting 1"}.length == 1)
		assert(log.interactions.find_all{|i| i == "1 targeting 2"}.length == 1)
		assert(log.interactions.find_all{|i| i == "1 targeting 1"}.length == 0)
		assert(log.interactions.find_all{|i| i == "2 targeting 2"}.length == 0)
		
	end
	
	
	#An environmental factor that logs its target.
	class LogFactor < EnvironmentalFactor
		attr_reader :interactions
		def initialize
			#Interactions will be logged here.
			@interactions = []
		end
		def act(target)
			#Log the interaction.
			@interactions << "Environment targeting #{target.name}"
		end
	end
	
	def test_environmental_factors
	
		#Create an environmental factor.
		logger = LogFactor.new
		@environment.environmental_factors << logger
		
		#Have environment elements interact.
		@environment.interact

		#Look for expected interactions (each should only occur once).
		assert(logger.interactions.find_all{|i| i == "Environment targeting 1"}.length == 1)
		assert(logger.interactions.find_all{|i| i == "Environment targeting 2"}.length == 1)
		
	end
	
	
	#A condition that is false unless actor and target have specific names.
	class NameCondition < Condition
		def test(actor, target)
			return true if actor.name == '1' and target.name == '2'
		end
	end
	
	def test_conditions
	
		#Set up behavior that will log interactions.
		behavior = Behavior.new
		log = LogAction.new
		behavior.actions << log
		name_checker = NameCondition.new
		behavior.conditions << name_checker
		@environment.objects.each {|creature| creature.behaviors << behavior}
				
		#Have environment elements interact.
		@environment.interact

		#Creature '1' should NOT have been acted on.
		assert(log.interactions.find_all{|i| i == "2 targeting 1"}.length == 0)
		#Creature '2' SHOULD have been acted on.
		assert(log.interactions.find_all{|i| i == "1 targeting 2"}.length == 1)
		
	end
	
	
	#Test that creatures can switch targets when one is removed from the environment.
	def test_object_removal
	
		#Set up behaviors that will log interactions.
		log = LogAction.new
		@environment.objects.each do |creature|
			behavior = Behavior.new
			behavior.actions << log
			creature.behaviors << behavior
		end
		
		#Have environment elements interact.
		@environment.interact
		#Remove the original target from the environment.
		@environment.objects.delete_at(1)
		#Interact again.
		@environment.interact

		#Look for expected interactions (each should only occur once).
		assert_equal(1, log.interactions.find_all{|i| i == "1 targeting 3"}.length)
		
	end
	
	
end



class TestColor < Test::Unit::TestCase
	
	def test_default_initialization
		color = Color.new
		assert_equal(1, color.red)
		assert_equal(1, color.green)
		assert_equal(1, color.blue)
	end
	
	def test_explicit_initialization
		color = Color.new(0.25, 0.5, 0.75)
		assert_equal(0.25, color.red)
		assert_equal(0.5, color.green)
		assert_equal(0.75, color.blue)
	end
	
	def test_constraints
		#Test at initialization.
		color = Color.new(-1, -1, -1)
		assert_equal(0, color.red)
		assert_equal(0, color.green)
		assert_equal(0, color.blue)
		color = Color.new(2, 2, 2)
		assert_equal(1, color.red)
		assert_equal(1, color.green)
		assert_equal(1, color.blue)
		#Test accessors.
		color = Color.new
		color.red = -1
		assert_equal(0, color.red)
		color.red = 2
		assert_equal(1, color.red)
		color.green = -1
		assert_equal(0, color.green)
		color.green = 2
		assert_equal(1, color.green)
		color.blue = -1
		assert_equal(0, color.blue)
		color.blue = 2
		assert_equal(1, color.blue)
	end
	
	
end



class TestVector < Test::Unit::TestCase


	def test_initialize
	
		vector = Vector.new
		assert_equal(0, vector.speed)
		assert_equal(0, vector.pitch)
		assert_equal(0, vector.x)
		assert_equal(0, vector.y)
		
	end

	
	def test_angles
	
		vector = Vector.new(4, 150)
		assert_in_delta(-3.464, vector.x, 0.001)
		assert_in_delta(2, vector.y, 0.001)

		vector = Vector.new(5, 53.13)
		assert_in_delta(3, vector.x, 0.001)
		assert_in_delta(4, vector.y, 0.001)

		vector = Vector.new(5, 233.13)
		assert_in_delta(-3, vector.x, 0.001)
		assert_in_delta(-4, vector.y, 0.001)

		vector = Vector.new(5, 306.87)
		assert_in_delta(3, vector.x, 0.001)
		assert_in_delta(-4, vector.y, 0.001)
		
		#Angles over 360 should 'wrap around' to 0.
		vector = Vector.new(5, 413.13) #360 + 53.13
		assert_in_delta(3, vector.x, 0.001)
		assert_in_delta(4, vector.y, 0.001)
		
		#Negative angle should be converted to positive equivalent.
		vector = Vector.new(5, -53.13) #360 - 53.13 = 306.87
		assert_in_delta(3, vector.x, 0.001)
		assert_in_delta(-4, vector.y, 0.001)
		
	end
	
	
	def test_components
	
		vector = Vector.new(1.4142, 45)
		assert_in_delta(1, vector.x, 0.001)
		assert_in_delta(1, vector.y, 0.001)
		
		vector = Vector.new(1.4142, 135)
		assert_in_delta(-1, vector.x, 0.001)
		assert_in_delta(1, vector.y, 0.001)
		
		vector = Vector.new(1.4142, 225)
		assert_in_delta(-1, vector.x, 0.001)
		assert_in_delta(-1, vector.y, 0.001)
		
		vector = Vector.new(1.4142, 315)
		assert_in_delta(1, vector.x, 0.001)
		assert_in_delta(-1, vector.y, 0.001)
				
	end
	
	
	def test_addition
			
		vector = Vector.new(1, 45) + Vector.new(1, 45) #Same angle.
		#Speed should be sum of added vectors' speeds.
		assert_in_delta(2, vector.speed, 0.001)
		#Angle should remain the same.
		assert_in_delta(45, vector.pitch, 0.001)
		
		#Vectors of opposite angles should cancel out.
		vector = Vector.new(2, 0) + Vector.new(1, 180)
		assert_in_delta(1, vector.speed, 0.001)
		assert_in_delta(0, vector.pitch, 0.001)
		vector = Vector.new(2, 45) + Vector.new(1, 225)
		assert_in_delta(1, vector.speed, 0.001)
		assert_in_delta(45, vector.pitch, 0.001)
		vector = Vector.new(2, 135) + Vector.new(1, 315)
		assert_in_delta(1, vector.speed, 0.001)
		assert_in_delta(135, vector.pitch, 0.001)
		vector = Vector.new(2, 225) + Vector.new(1, 45)
		assert_in_delta(1, vector.speed, 0.001)
		assert_in_delta(225, vector.pitch, 0.001)
		vector = Vector.new(2, 315) + Vector.new(1, 135)
		assert_in_delta(1, vector.speed, 0.001)
		assert_in_delta(315, vector.pitch, 0.001)
		
	end
	
	
end



class TestUtility < Test::Unit::TestCase
	
	
	def test_to_radians
	
		assert_in_delta(0, Utility.to_radians(0), 0.01)
		assert_in_delta(Math::PI, Utility.to_radians(180), 0.01)
		assert_in_delta(Math::PI * 2, Utility.to_radians(359), 0.1)
		
	end

	
	def test_to_degrees
	
		assert_in_delta(0, Utility.to_degrees(0), 0.01)
		assert_in_delta(180, Utility.to_degrees(Math::PI), 0.01)
		assert_in_delta(359, Utility.to_degrees(Math::PI * 2 - 0.0001), 1)
		
	end
	
	
	def test_find_angle
		origin = Location.new(0, 0)
		assert_in_delta(0, Utility.find_angle(origin, Location.new(1,0)), 0.001)
		assert_in_delta(90, Utility.find_angle(origin, Location.new(0,1)), 0.001)
		assert_in_delta(45, Utility.find_angle(origin, Location.new(1,1)), 0.001)
		assert_in_delta(135, Utility.find_angle(origin, Location.new(-1,1)), 0.001)
		assert_in_delta(225, Utility.find_angle(origin, Location.new(-1,-1)), 0.001)
		assert_in_delta(315, Utility.find_angle(origin, Location.new(1,-1)), 0.001)
	end

	
	def test_find_distance
		origin = Location.new(0, 0)
		assert_in_delta(1, Utility.find_distance(origin, Location.new(1,0)), 0.001)
		assert_in_delta(1, Utility.find_distance(origin, Location.new(0,1)), 0.001)
		assert_in_delta(1.4142, Utility.find_distance(origin, Location.new(1,1)), 0.001)
		assert_in_delta(1.4142, Utility.find_distance(origin, Location.new(-1,1)), 0.001)
		assert_in_delta(1.4142, Utility.find_distance(origin, Location.new(-1,-1)), 0.001)
		assert_in_delta(1.4142, Utility.find_distance(origin, Location.new(1,-1)), 0.001)
	end
	
	
	def test_find_reflection_angle
		assert_equal(210, Utility.find_reflection_angle(0, 150))
		assert_equal(330, Utility.find_reflection_angle(0, 30))
		assert_equal(150, Utility.find_reflection_angle(90, 30))
		assert_equal(210, Utility.find_reflection_angle(90, 330))
		assert_equal(30, Utility.find_reflection_angle(180, 330))
		assert_equal(150, Utility.find_reflection_angle(180, 210))
		assert_equal(330, Utility.find_reflection_angle(270, 210))
		assert_equal(30, Utility.find_reflection_angle(270, 150))
	end

	
	def test_collided?
		#Objects apart.
		assert(! Utility.collided?(
			GameObject.new("", Location.new(0, 0), Color.new, Vector.new, 0, 0.196), #Radius = 0.25
			GameObject.new("", Location.new(1, 0), Color.new, Vector.new, 0, 0.196)
		))
		#Objects touching (not a collision).
		assert(! Utility.collided?(
			GameObject.new("", Location.new(0, 0), Color.new, Vector.new, 0, 0.785), #Radius = 0.5
			GameObject.new("", Location.new(1, 0), Color.new, Vector.new, 0, 0.785)
		))
		#Objects collided.
		assert(Utility.collided?(
			GameObject.new("", Location.new(0, 0), Color.new, Vector.new, 0, 1.766), #Radius = 0.75
			GameObject.new("", Location.new(1, 0), Color.new, Vector.new, 0, 1.766)
		))
		#Objects in same place.
		assert(Utility.collided?(
			GameObject.new("", Location.new(0, 0)),
			GameObject.new("", Location.new(0, 0))
		))
	end
	
end


class TestBehavior < Test::Unit::TestCase

	#Always true.
	class TrueCondition < Condition
		def test(actor, target)
			true
		end
	end
	#Always false.
	class FalseCondition < Condition
		def test(actor, target)
			false
		end
	end
	
	
	def setup
		@actor = Creature.new('actor')
		@target = Creature.new('target')
		@other = Creature.new('other')
	end
	
	
	def test_return_values
	
		#Set up a Behavior with a true condition.
		behavior = Behavior.new
		behavior.conditions << TrueCondition.new
		assert(behavior.perform(@actor, @target), "perform() should return true.")
		
		#Set up a Behavior with a false condition.
		behavior = Behavior.new
		behavior.conditions << FalseCondition.new
		assert(! behavior.perform(@actor, @target), "perform() should return true.")
		
		#Set up a Behavior with a true and a false condition.
		behavior = Behavior.new
		behavior.conditions << TrueCondition.new
		behavior.conditions << FalseCondition.new
		assert(! behavior.perform(@actor, @target), "perform() should return false.")
		
		#Set up a behavior with no conditions.
		behavior = Behavior.new
		assert(behavior.perform(@actor, @target), "perform() should return true.")
		
	end

	
	#Tracks number of times its start, stop, and do methods are called.
	class MockAction < Action
		attr_accessor :start_count, :stop_count, :do_count
		def initialize
			@start_count, @stop_count, @do_count = 0, 0, 0
		end
		def start(actor, target)
			super
			@start_count += 1
		end
		def do(actor, target)
			@do_count += 1
		end
		def stop(actor, target)
			super
			@stop_count += 1
		end
	end
	
	def test_actions
	
		#Set up a behavior with a true condition and a mock action.
		behavior = Behavior.new
		behavior.conditions << TrueCondition.new
		action = MockAction.new
		behavior.actions << action
		
		#Perform the behavior.
		behavior.perform(@actor, @target)
		assert_equal(1, action.start_count, "start() should have been called on the mock action.")
		assert_equal(1, action.do_count, "do() should have been called.")
		assert_equal(0, action.stop_count, "stop() should NOT have been called.")
		
		#Perform the behavior again.
		behavior.perform(@actor, @target)
		assert_equal(1, action.start_count, "start() should NOT have been called.")
		assert_equal(2, action.do_count, "do() should have been called.")
		assert_equal(0, action.stop_count, "stop() should NOT have been called.")
		
		#Add a false condition to the behavior.
		behavior.conditions << FalseCondition.new
		#Perform the behavior.
		behavior.perform(@actor, @target)
		assert_equal(1, action.start_count, "start() should NOT have been called.")
		assert_equal(2, action.do_count, "do() should have been called, because action is already started.")
		assert_equal(1, action.stop_count, "stop() should NOT have been called.")
				
	end
	
	
	#True only if actor's name is "actor" and target's name is "target".
	class ActorTargetCondition < Condition
		def test(actor, target)
			return true if actor.name == 'actor' and target.name == 'target'
			false
		end
	end
	
	def test_continuity
	
		#Set up a behavior with a condition that is only true for the actor and target objects.
		behavior = Behavior.new
		behavior.conditions << ActorTargetCondition.new
		action = MockAction.new
		behavior.actions << action
		
		#Perform the behavior on the actor and target.
		behavior.perform(@actor, @target)
		assert_equal(1, action.start_count, "start() should have been called on the mock action.")
		assert_equal(1, action.do_count, "do() should have been called.")
		assert_equal(0, action.stop_count, "stop() should NOT have been called.")
		
		#Perform the behavior on the actor and some other target (so the condition is false).
		behavior.perform(@actor, @other)
		assert_equal(1, action.start_count, "start() should NOT have been called, because the condition is false.")
		assert_equal(1, action.do_count, "do() should NOT have been called, because the action is locked.")
		assert_equal(0, action.stop_count, "stop() should NOT have been called, because the action is locked.")
		
		#Perform the behavior on the actor and original target again.
		behavior.perform(@actor, @target)
		assert_equal(1, action.start_count, "start() should NOT have been called, because the action is already started.")
		assert_equal(2, action.do_count, "do() should have been called.")
		assert_equal(0, action.stop_count, "stop() should NOT have been called.")
		
		#Change the target's name so the condition becomes false, then perform again.
		@target.name = 'foobar'
		behavior.perform(@actor, @target)
		assert_equal(1, action.start_count, "start() should NOT have been called, because the condition is false.")
		assert_equal(2, action.do_count, "do() should NOT have been called, because the condition is false.")
		assert_equal(1, action.stop_count, "stop() should have been called.")
		
		#Change the target's name so the condition becomes true again, then perform again.
		@target.name = 'target'
		behavior.perform(@actor, @target)
		assert_equal(2, action.start_count, "start() should have been called.")
		assert_equal(3, action.do_count, "do() should have been called.")
		assert_equal(1, action.stop_count, "stop() should NOT have been called.")
		
	end
	
	
end