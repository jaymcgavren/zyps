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
require 'zyps/environmental_factors'
require 'test/unit'


#Redefine Clock to return a predictable time.
class Clock
	def elapsed_time; 0.1; end
end


class TestEnclosure < Test::Unit::TestCase


	def test_enclosure
	
		creature = Creature.new
		
		#Create an enclosure.
		enclosure = Enclosure.new
		enclosure.left = 1
		enclosure.top = 3
		enclosure.right = 3
		enclosure.bottom = 1
		
		#Place creature outside the walls, and act on it.
		#Ensure it's moved inside and its heading reflects off the walls.
		creature.location = Location.new(0, 2) #Too far left.
		creature.vector.pitch = 170
		enclosure.act(creature)
		assert_equal(1, creature.location.x)
		assert_equal(2, creature.location.y)
		assert_equal(10, creature.vector.pitch)
		
		creature.location = Location.new(4, 2) #Too far right.
		creature.vector.pitch = 10
		enclosure.act(creature)
		assert_equal(3, creature.location.x)
		assert_equal(2, creature.location.y)
		assert_equal(170, creature.vector.pitch)
		
		creature.location = Location.new(2, 0) #Too far down.
		creature.vector.pitch = 280
		enclosure.act(creature)
		assert_equal(2, creature.location.x)
		assert_equal(1, creature.location.y)
		assert_equal(80, creature.vector.pitch)
		
		creature.location = Location.new(2, 4) #Too far up.
		creature.vector.pitch = 80
		enclosure.act(creature)
		assert_equal(2, creature.location.x)
		assert_equal(3, creature.location.y)
		assert_equal(280, creature.vector.pitch)
		
		#Place creature inside the walls, and ensure it's unaffected.
		creature.location = Location.new(2, 2) #Inside.
		creature.vector.pitch = 45
		enclosure.act(creature)
		assert_equal(2, creature.location.x)
		assert_equal(2, creature.location.y)
		assert_equal(45, creature.vector.pitch)
		
	end
	
	
end



