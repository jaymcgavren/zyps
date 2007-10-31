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
require 'zyps/conditions'
require 'test/unit'


include Zyps


class TestConditions < Test::Unit::TestCase


	def setup
		@actor = Creature.new('name', Location.new(1, 1))
		@target = GameObject.new('name', Location.new(2, 2))
	end


	def test_tag_condition
		condition = TagCondition.new("tag")
		#Test for falsehood.
		assert(! condition.met?(@actor, @target))
		#Test for truth.
		@target.tags << "tag"
		assert(condition.met?(@actor, @target))
	end
	
	
	def test_age_condition
		condition = AgeCondition.new(0.2)
		#Test for falsehood.
		@target.age = 0.1
		assert(! condition.met?(@actor, @target))
		#Test for truth.
		@target.age = 0.2
		assert(condition.met?(@actor, @target))
		@target.age = 0.3
		assert(condition.met?(@actor, @target))
	end
	
	
	def test_proximity_condition
		condition = ProximityCondition.new(1)
		#Test for falsehood.
		assert(! condition.met?(@actor, @target))
		#Test for truth.
		@target.location = Location.new(0.5, 0.5)
		assert(condition.met?(@actor, @target))
	end
	
	
	def test_collision_condition
		condition = CollisionCondition.new
		#Test for falsehood.
		@actor.size, @target.size = 0.196, 0.196 #Radius = 0.25
		assert(! condition.met?(@actor, @target))
		#Test for truth.
		@actor.size, @target.size = 1.766, 1.766 #Radius = 0.75
		assert(condition.met?(@actor, @target))
	end
	
	
end
