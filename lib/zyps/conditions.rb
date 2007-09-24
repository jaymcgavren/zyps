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
	#The tag to look for on the target.
	attr_accessor :tag
	def initialize(tag)
		self.tag = tag
	end
	#True if the target has the assigned tag.
	def met?(actor, target)
		target.tags.include?(@tag)
	end
end


#Act only on objects older than the given age.
class AgeCondition < Condition
	#The minimum age in seconds.
	attr_accessor :age
	def initialize(age)
		self.age = age
	end
	#True if the target is older than the assigned age.
	def met?(actor, target)
		target.age > @age
	end
end


#Act only on objects closer than the given distance.
class ProximityCondition < Condition
	#The maximum number of units away the target can be.
	attr_accessor :distance
	def initialize(distance)
		self.distance = distance
	end
	#True if the actor and target are equal to or closer than the given distance.
	def met?(actor, target)
		Utility.find_distance(actor.location, target.location) <= @distance
	end
end


#True only if collided with target.
class CollisionCondition < Condition
	#True if the objects have collided.
	def met?(actor, target)
		Utility.collided?(actor, target)
	end
end
