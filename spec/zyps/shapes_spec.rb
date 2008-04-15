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


gems_loaded = false
begin
	require 'spec'
	require 'zyps'
	require 'zyps/shapes'
	require 'zyps/views/canvas'
rescue LoadError
	if gems_loaded == false
		require 'rubygems'
		gems_loaded = true
		retry
	else
		raise
	end
end


include Zyps


describe Rectangle do

	before(:each) do
		@shape = Rectangle.new
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
		@shape.draw(view, Location.new(0, 0))
	end
	
	it "collides with Locations inside it" do
		@shape.should satisfy do |shape|
			shape.collided?(
				Location.new(0, 0), #This shape's current Location.
				Location.new(0, 0), #This shape's prior Location.
				Location.new(0.5, 0.5), #The other shape's current Location.
				Location.new(0.5, 0.5) #The other shape's prior Location.
			)
		end
	end
	
	it "collides with Locations that have passed through it since the prior frame" do
		@shape.should satisfy {|shape| shape.collided?(Location.new(-1, 0.5), Location.new(2, 0.5), Location.new(0, 0))}
		@shape.should satisfy do |shape|
			shape.collided?(
				Location.new(0, 0), #This shape's current Location.
				Location.new(0, 0), #This shape's prior Location.
				Location.new(2, 0.5), #The other shape's current Location.
				Location.new(-1, 0.5) #The other shape's prior Location.
			)
		end
	end

end


describe Zyp do

	before(:each) do
		@shape = Zyp.new
	end

	it "has a default size" do
		@shape.size.should == 1
	end

	it "draws itself to Views when it has 1 segment" do
		view = View.new
		@shape.size = 100
		@shape.color = Color.white
		@shape.add_segment_end Location.new(0, 0)
		view.should_receive(:draw_line).with(
			:location_1 => Location.new(1, 1),
			:location_2 => Location.new(0, 0),
			:width => 23.664,
			:color => Color.white
		)
		@shape.draw(view, Location.new(1, 1))
	end
	
	it "draws itself to Views when it has 2 segments" do
		view = View.new
		@shape.size = 100
		@shape.color = Color.white
		@shape.add_segment_end Location.new(15, 12)
		@shape.add_segment_end Location.new(16, 14)
		view.should_receive(:draw_line).with(
			:location_1 => Location.new(10, 10),
			:location_2 => @shape.segment_ends[0],
			:width => 23.664,
			:color => Color.white
		)
		view.should_receive(:draw_line).with(
			:location_1 => @shape.segment_ends[0],
			:location_2 => @shape.segment_ends[1],
			:width => 11.832,
			:color => Color.new(0.5, 0.5, 0.5)
		)
		@shape.draw(view, Location.new(10, 10))
	end
	
	it "draws itself to Views when it has 3 segments"
	it "draws itself to Views when it has 100 segments"
	
	it "drops prior segment end locations when over its maximum segment count" do
		@shape.max_segment_count = 2
		@shape.add_segment_end Location.new(1, 1)
		@shape.add_segment_end Location.new(2, 2)
		@shape.add_segment_end Location.new(3, 3) #Over the limit.
		view = View.new
		view.should_receive(:draw_line).twice
		@shape.draw(view, Location(0, 0))
	end
	
	it "collides with Locations inside it"
	
	it "collides with Locations that have passed through it since the prior frame"
	
	it "should report the normal from its surface for a given point of impact"

end