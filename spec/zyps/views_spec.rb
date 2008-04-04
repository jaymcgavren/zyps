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
require 'zyps/shapes'
require 'zyps/views'
require 'zyps/views/canvas'


include Zyps


describe View do

	before(:each) do
		@view = View.new
	end

	it "has no Canvas by default"
	it "has a scale of 1 by default"
	it "has an origin of 0, 0 by default"
	it "erases between frames by default"
	it "has a black background by default"
	
	it "corrects for scale when drawing rectangles to a Canvas" do
		@view.scale = 0.5
		@view.canvas = Canvas.new
		@view.canvas.should_receive(:draw_rectangle).with(
			:x => 0.5,
			:y => 1,
			:width => 2,
			:height => 1
		)
		@view.draw_rectangle(
			:x => 1,
			:y => 2,
			:width => 4,
			:height => 2
		)
	end
	
	it "corrects for origin when drawing rectangles to a Canvas"
	
	it "corrects for scale when drawing lines to a Canvas"
	it "corrects for origin when drawing lines to a Canvas"
	
end
