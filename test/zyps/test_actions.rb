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


class TestActions < Test::Unit::TestCase


	#Redefine Clock to return a predictable time.
	class Clock
		def elapsed_time; 0.1; end
	end
	
	
	def setup
		@actor = Creature.new('name', Location.new(0, 0))
		@target = GameObject.new('name', Location.new(1, 1))
	end


	def test_face_action
		FaceAction.new.do(@actor, @target)
		assert_equal(45, @actor.vector.pitch)
	end
	
	
	def test_accelerate_action
		AccelerateAction.new.do(@actor, @target)
		assert_equal(0.1, @actor.vector.speed)
	end
	
	
end
