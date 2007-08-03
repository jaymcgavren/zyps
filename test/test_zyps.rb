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


class TestGameObject < Test::Unit::TestCase


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
		assert_in_delta(0, creature.age, 0.1)
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
		assert_in_delta(2.001, creature.age, 0.01)
		assert(creature.tags.include?("predator"))
		assert(creature.tags.include?("blue team"))
		assert(creature.behaviors.include?(behavior))
	end
	
	
end



class TestEnvironment < Test::Unit::TestCase

	def setup
	
		#Interactions will be logged here.
		@interactions = []
		
		#Create creatures.
		creature1 = Creature.new('1')
		creature2 = Creature.new('2')
		creature_behavior = Behavior.new
		creature_behavior.actions << lambda {|creature, target| @interactions << "#{creature.name} targeting #{target.name}"}
		creature1.behaviors << creature_behavior
		creature2.behaviors << creature_behavior
		
		#Create an environment and add the creatures.
		@environment = Environment.new([creature1, creature2])
		
	end
	
	
	def test_interactions
	
		#Have environment elements interact.
		@environment.interact

		#Look for expected interactions (each should only occur once).
		assert(@interactions.find_all{|i| i == "2 targeting 1"}.length == 1)
		assert(@interactions.find_all{|i| i == "1 targeting 2"}.length == 1)
		assert(@interactions.find_all{|i| i == "1 targeting 1"}.length == 0)
		assert(@interactions.find_all{|i| i == "2 targeting 2"}.length == 0)
		
	end
	
	
	def test_environmental_factors
	
		#Create an environmental factor.
		behavior = Behavior.new
		behavior.actions << lambda {|factor, target| @interactions << "Environment targeting #{target.name}"}
		@environment.environmental_factors << EnvironmentalFactor.new([behavior])
		
		#Have environment elements interact.
		@environment.interact

		#Look for expected interactions (each should only occur once).
		assert(@interactions.find_all{|i| i == "Environment targeting 1"}.length == 1)
		assert(@interactions.find_all{|i| i == "Environment targeting 2"}.length == 1)
		
	end
	
	
	def test_conditions
	
		#Change behaviors to only occur if the target's name is '2'.
		@environment.objects.each do |creature|
			behavior = Behavior.new
			behavior.conditions << lambda do |creature, target|
				return true if creature.name == '1' and target.name == '2'
			end
			behavior.actions << lambda do |creature, target|
				@interactions << "#{creature.name} is targeting #{target.name}"
			end
			creature.behaviors << behavior
		end
		
		#Have environment elements interact.
		@environment.interact

		#Creature '1' should not have been acted on.
		assert(@interactions.find_all{|i| i == "2 is targeting 1"}.length == 0)
		#Creature '2' *should* have been acted on.
		assert(@interactions.find_all{|i| i == "1 is targeting 2"}.length == 1)
		
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



class TestClock < Test::Unit::TestCase


	def test_elapsed_time
	
		#Create a clock, wait a moment, then see how much time has elapsed since its creation.
		clock = Clock.new
		sleep 0.1
		assert_in_delta(0.1, clock.elapsed_time, 0.02)
		
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
	
	
	def test_find_reflection_angle(normal, incidence_angle)
		assert_equals(135, Utility.find_reflection_angle(180, 45)) #right barrier, up-right, up-left
		assert_equals(225, Utility.find_reflection_angle(180, 315)) #right barrier, down-right, down-left
		assert_equals(225, Utility.find_reflection_angle(270, 135)) #top barrier, up-left, down-left
		assert_equals(315, Utility.find_reflection_angle(270, 45)) #top barrier, up-right, down-right
		assert_equals(45, Utility.find_reflection_angle(0, 135)) #left barrier, up-left, up-right
		assert_equals(315, Utility.find_reflection_angle(0, 315)) #left barrier, down-left, down-right
		assert_equals(135, Utility.find_reflection_angle(90, 225)) #bottom barrier, down-left, up-left
		assert_equals(45, Utility.find_reflection_angle(90, 315)) #bottom barrier, down-right, up-right
	end

	
end
