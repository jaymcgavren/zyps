# Copyright 2007-2009 Zyps Contributors.
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
require 'zyps/conditions'
require 'zyps/environmental_factors'
require 'test/unit'


include Zyps

class TestVector < Test::Unit::TestCase


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

	
	def setup
		Utility.caching_enabled = true
	end
	
	
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
			GameObject.new(:location => Location.new(0, 0), :size =>0.196), #Radius = 0.25
			GameObject.new(:location => Location.new(1, 0), :size =>0.196)
		))
		#Objects touching (not a collision).
		assert(! Utility.collided?(
			GameObject.new(:location => Location.new(0, 0), :size =>0.785), #Radius = 0.5
			GameObject.new(:location => Location.new(1, 0), :size =>0.785)
		))
		#Objects collided.
		assert(Utility.collided?(
			GameObject.new(:location => Location.new(0, 0), :size =>1.766), #Radius = 0.75
			GameObject.new(:location => Location.new(1, 0), :size =>1.766)
		))
		#Objects in same place.
		assert(Utility.collided?(
			GameObject.new(:location => Location.new(0, 0)),
			GameObject.new(:location => Location.new(0, 0))
		))
	end
	
end


class TestBehavior < Test::Unit::TestCase


	def setup
		@actor = Creature.new(:name => 'actor')
		@target = Creature.new(:name => 'target')
		@other = Creature.new(:name => 'other')
		@targets = []
		@targets << @target << @other
	end
	
	
	def test_equality
		#Equivalent behaviors have the same actions.
		assert_equal(
			Behavior.new(:actions => [ApproachAction.new(1), TagAction.new('foo')]),
			Behavior.new(:actions => [ApproachAction.new(1), TagAction.new('foo')]),
			"Same actions."
		)
		assert_not_equal(
			Behavior.new(:actions => [ApproachAction.new(1)]),
			Behavior.new(:actions => [ApproachAction.new(2)]),
			"Action attributes differ."
		)
		assert_not_equal(
			Behavior.new(:actions => [ApproachAction.new(1)]),
			Behavior.new(:actions => [ApproachAction.new(1), ApproachAction.new(1)]),
			"Action counts differ."
		)
		#Equivalent behaviors have the same conditions.
		assert_equal(
			Behavior.new(:conditions => [ProximityCondition.new(1), TagCondition.new('foo')]),
			Behavior.new(:conditions => [ProximityCondition.new(1), TagCondition.new('foo')]),
			"Same conditions."
		)
		assert_not_equal(
			Behavior.new(:conditions => [ProximityCondition.new(1)]),
			Behavior.new(:conditions => [ProximityCondition.new(2)]),
			"Condition attributes differ."
		)
		assert_not_equal(
			Behavior.new(:conditions => [ProximityCondition.new(1)]),
			Behavior.new(:conditions => [ProximityCondition.new(1), ProximityCondition.new(1)]),
			"Condition counts differ."
		)
		#Equivalent behaviors have the same condition frequency.
		assert_equal(
			Behavior.new(:condition_frequency => 2),
			Behavior.new(:condition_frequency => 2),
			"Same condition frequency."
		)
		assert_not_equal(
			Behavior.new(:condition_frequency => 2),
			Behavior.new(:condition_frequency => 3),
			"Condition frequencies differ."
		)
		#Test everything at once.
		assert_equal(
			Behavior.new(
				:actions => [ApproachAction.new(1), TagAction.new('foo')],
				:conditions => [ProximityCondition.new(1), TagCondition.new('foo')],
				:condition_frequency => 2
			),
			Behavior.new(
				:actions => [ApproachAction.new(1), TagAction.new('foo')],
				:conditions => [ProximityCondition.new(1), TagCondition.new('foo')],
				:condition_frequency => 2
			),
			"Condition frequency and all actions and conditions match."
		)
	end
	
end
