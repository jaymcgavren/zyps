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
require 'zyps/views'
require 'test/unit'


include Zyps


class TestViews < Test::Unit::TestCase

	def setup
		@view = View.new(
			:scale => 1,
			:origin => Location.new(0, 0),
			:width => 200,
			:height => 100,
			:background_color => Color.black,
			:erase_flag => false
		)
	end
	
	def test_drawing_coordinates
		#Test at normal scale and origin.
		assert_equal(
			[1, 2],
			@view.drawing_coordinates(Location.new(1, 2)),
			"View with scale #{@view.scale} and origin #{@view.origin}."
		)
		#Test with altered scale.
		@view.scale = 0.1
		assert_equal(
			[0.1, 0.2],
			@view.drawing_coordinates(Location.new(1, 2)),
			"View with scale #{@view.scale} and origin #{@view.origin}."
		)
		#Test with altered origin.
		@view.scale = 1
		@view.origin = Location.new(3, 4)
		assert_equal(
			[-2, -2],
			@view.drawing_coordinates(Location.new(1, 2)),
			"View with scale #{@view.scale} and origin #{@view.origin}."
		)
		#Test with altered scale and origin.
		@view.scale = 2
		@view.origin = Location.new(3, 4)
		assert_equal(
			[-4, -4],
			@view.drawing_coordinates(Location.new(1, 2)),
			"View with scale #{@view.scale} and origin #{@view.origin}."
		)
	end
	
	def test_drawing_width
		#Test at normal scale.
		assert_equal(1, @view.drawing_width(1), "View with scale #{@view.scale}.")
		#Test at increased scale.
		@view.scale = 2.3
		assert_equal(2.3, @view.drawing_width(1), "View with scale #{@view.scale}.")
		#Test at reduced scale.
		@view.scale = 0.1
		assert_equal(1, @view.drawing_width(10), "View with scale #{@view.scale}.")
	end

end