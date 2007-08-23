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


#Act only on objects with the correct tag.
class TagCondition < Condition
	attr_accessor :tag
	def initialize(tag)
		self.tag = tag
	end
	def test(creature, target)
		target.tags.include?(@tag)
	end
end


#Act only on objects older than the given age.
class AgeCondition < Condition
	attr_accessor :age
	def initialize(age)
		self.age = age
	end
	def test(creature, target)
		target.age > @age
	end
end


#Act only on objects closer than the given distance.
class ProximityCondition < Condition
	attr_accessor :distance
	def initialize(distance)
		self.distance = distance
	end
	def test(creature, target)
		Utility.find_distance(creature.location, target.location) < @distance
	end
end


#True only if collided with target.
class CollisionCondition < Condition
	def test(creature, target)
		Utility.collided?(creature, target)
	end
end
