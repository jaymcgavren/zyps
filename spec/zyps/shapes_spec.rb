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
require 'zyps/views/canvas'


include Zyps


describe Rectangle do

	before(:each) do
		@shape = Rectangle.new
	end

	it "has a default Location" do
		@shape.location.should == Location.new(0, 0)
	end
	
	it "has a default size" do
		@shape.width.should == 1
		@shape.height.should == 1
	end
	
	it "has a default Color" do
		@shape.color.should == Color.new
	end
	
	it "draws itself to Views" do
		view = View.new
		view.should_receive(:draw_rectangle).with(
			:color => Color.new,
			:x => 0,
			:y => 0,
			:width => 1,
			:height => 1
		)
		@shape.draw(view)
	end
	
	it "collides with Locations inside it" do
		@shape.should satisfy {|shape| shape.collided?(Location.new(0.5, 0.5), Location.new(0.5, 0.5))}
	end
	
	it "collides with Locations that have passed through it since the prior frame" do
		@shape.should satisfy {|shape| shape.collided?(Location.new(-1, 0.5), Location.new(2, 0.5))}
	end

end


describe Zyp do

	before(:each) do
		@shape = Zyp.new
	end

	it "has a default size" do
		@shape.size.should == 1
	end

	it "draws itself to Views"
	
	it "collides with Locations inside it"
	
	it "collides with Locations that have passed through it since the prior frame"

end