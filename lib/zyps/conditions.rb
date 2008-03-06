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

require 'zyps'


module Zyps


#Select objects with the correct tag.
class TagCondition < Condition
	#The tag to look for on the target.
	attr_accessor :tag
	def initialize(tag)
		self.tag = tag
	end
	#Returns an array of targets which have the assigned tag.
	def select(actor, targets)
		targets.find_all {|target| target.tags.include?(@tag)}
	end
end


#Select objects older than the given age.
class AgeCondition < Condition
	#The minimum age in seconds.
	attr_accessor :age
	def initialize(age)
		self.age = age
	end
	#Returns an array of targets which are older than the assigned age.
	def select(actor, targets)
		targets.find_all {|target| target.age > @age}
	end
end


#Select objects that are closer than the given distance.
class ProximityCondition < Condition
	#The maximum number of units away the target can be.
	attr_accessor :distance
	def initialize(distance)
		self.distance = distance
	end
	#Returns an array of targets that are at the given distance or closer.
	def select(actor, targets)
		targets.find_all {|target| Utility.find_distance(actor.location, target.location) <= @distance}
	end
end


#True only if collided with target.
class CollisionCondition < Condition
	#Returns an array of targets that have collided with the actor.
	def select(actor, targets)
		return [] unless targets.length > 0
		#The size of the largest other object
		max_size = targets.map{|t| t.size}.max
		#The maximum distance on a straight line the largest object and self could be and still be touching.
		max_diff = Math.sqrt(actor.size / Math::PI) + Math.sqrt(max_size / Math::PI)
		x_range = (actor.location.x - max_diff .. actor.location.x + max_diff)
		y_range = (actor.location.y - max_diff .. actor.location.y + max_diff)
		targets.select do | target |
			x_range.include?(target.location.x) and y_range.include?(target.location.y) and Utility.collided?(actor, target)
		end
	end
end


#True if the actor's strength is equal to or greater than the target's. 
class StrengthCondition < Condition
	#Returns an array of targets that are weaker than the actor.
	#For now, strength is based merely on size.
	def select(actor, targets)
		targets.find_all {|target| actor.size >= target.size}
	end
end


#True if the actor and target are of the same Ruby class.
class ClassCondition < Condition
	#The class of target to look for.
	attr_accessor :target_class
	def initialize(target_class)
		self.target_class = target_class
	end
	#Returns an array of targets that are of the selected Ruby class.
	def select(actor, targets)
		targets.grep(target_class)
	end
end


#True if the given interval has elapsed since targets were last selected.
class ElapsedTimeCondition < Condition
	#The number of seconds that must elapse before the condition is true.
	attr_accessor :interval
	def initialize(interval = 1.0)
		self.interval = interval
		@clock = Clock.new
		@elapsed_time = 0
	end
	#Returns the array of targets if the interval has elapsed.
	def select(actor, targets)
		@elapsed_time += @clock.elapsed_time
		if ! targets.empty? and @elapsed_time >= self.interval
			@elapsed_time = 0
			return targets
		else
			return []
		end
	end
end


end #module Zyps
