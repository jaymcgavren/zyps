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


include Zyps


describe Rectangle do

	before(:each) do
		@shape = Rectangle.new
	end

	it "should have a default Location" do
		@shape.location.should equal(Location.new(0, 0))
	end
	
	it "should have a default size" do
		@shape.width.should equal(1)
		@shape.height.should equal(1)
	end
	
	it "should have a default Color" do
		@shape.color.should equal(Color.new)
	end
	
	it "should draw itself to Canvases" do
		canvas = Canvas.new
		canvas.should_receive(:draw_rectangle).with(
			:color => Color.new,
			:x => 0,
			:y => 0,
			:width => 1,
			:height => 1
		)
		shape.draw(canvas)
	end
	
	it "should collide with Locations inside it" do
		@shape.should satisfy {|shape| shape.collided?(Location.new(0.5, 0.5), Location.new(0.5, 0.5))}
	end
	
	it "should collide with Locations that have passed through it since the prior frame" do
		@shape.should satisfy {|shape| shape.collided?(Location.new(-1, 0.5), Location.new(2, 0.5))}
	end

end
