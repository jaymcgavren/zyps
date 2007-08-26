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


#Keeps all objects within a set of walls.
class Enclosure < EnvironmentalFactor
	
	#X coordinate of left boundary.
	attr_accessor :left
	#Y coordinate of top boundary.
	attr_accessor :top
	#X coordinate of right boundary.
	attr_accessor :right
	#Y coordinate of bottom boundary.
	attr_accessor :bottom
	def initialize(left = 0, top = 0, right = 0, bottom = 0)
		self.left, self.top, self.right, self.bottom = left, top, right, bottom
	end
	#If object is beyond a boundary, set its position equal to the boundary and reflect it.
	def act(object)
		if (object.location.x < @left) then
			object.location.x = @left
			object.vector.pitch = Utility.find_reflection_angle(90, object.vector.pitch)
		elsif (object.location.x > @right) then
			object.location.x = @right
			object.vector.pitch = Utility.find_reflection_angle(270, object.vector.pitch)
		end
		if (object.location.y > @top) then
			object.location.y = @top
			object.vector.pitch = Utility.find_reflection_angle(0, object.vector.pitch)
		elsif (object.location.y < @bottom) then
			object.location.y = @bottom
			object.vector.pitch = Utility.find_reflection_angle(180, object.vector.pitch)
		end
	end
end



