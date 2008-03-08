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


require 'spec/story'
require 'zyps'

load File.join(File.dirname(__FILE__), '..', 'lib', 'object_manager.rb')


include Zyps



$om = ObjectManager.new
$om.on_create("target") {Creature.new}

steps_for(:all) do


	#Given a creature at "1", "2"
	#Given a game object at "1", "3.1415"
	#Given a target at "1", "2"
	Given /(.+?) at "([\d\.]+?)", "([\d\.]+?)"/ do |subject, x, y|
		location = Location.new(x.to_f, y.to_f)
		$om.resolve_objects(subject).each do |s|
			s << location
			(@environment ||= Environment.new) << s
		end
	end
	
	#Given a creature with a speed of "10.2" and an angle of "45"
	#Given a game object with a speed of "10" and a pitch of "45"
	#Given a target with a speed of "10" and a pitch of "45"
	Given /(.+?) with a speed of "([\d\.]+?)" and an? (?:angle|pitch) of "([\d\.]+?)"/ do |subject, speed, pitch|
		vector = Vector.new(speed.to_f, pitch.to_f)
		$om.resolve_objects(subject).each do |s|
			s << vector
			(@environment ||= Environment.new) << s
		end
	end
	
	#Given an approach action initialized with a rate of "0.1"
	#Given a tag condition with a tag of "foobar"
	Given /^an? (\w+) (action|condition) (initialized )?with an? (\w+) of "([\d\.]+?)"/ do |name, type, use_constructor, attribute, value|
		#If attribute values are to be passed to constructor, do so.
		if use_constructor == "initialized "
			object = Object.const_get(name.capitalize + type.capitalize).new(value)
		else
			object = Object.const_get(name.capitalize + type.capitalize).new
			object.method(attribute).call(value.to_f)
		end
		@behaviors.last << object
	end
	#Given a turn action initialized with a rate of "0.1" and an angle of "45"
	#Given a foobar condition with a foo of "bar" and a baz of "0.2"
	Given /^an? (\w+?) (action|condition) (initialized )?with an? (\w+) of "([\d\.]+?)" and an? (\w+) of "([\d\.]+?)"/ do |name, type, use_constructor, attribute1, value1, attribute2, value2|
		if use_constructor == "initialized "
			object = Object.const_get(name.capitalize + type.capitalize).new(value1, value2)
		else
			object = Object.const_get(name.capitalize + type.capitalize).new
			object.method(attribute1).call(value1.to_f)
			object.method(attribute2).call(value2.to_f)
		end
		@behaviors.last << object
	end

	
	When %Q{the environment interacts} do
		@environment.interact
	end
	
	When /"([\d\.]+?)" seconds? elapses?/ do |seconds|
		#Monkey-patch Time to return the given number of seconds when Clock calls it.
		Time.class_eval "def to_f; #{seconds}; end"
	end
	
	
	Then %Q{the creature's location should be "$x", "$y"} do |x, y|
		@creatures.last.vector.should == Vector.new(x, y)
	end
	
	Then %Q{the creature's speed should be "$speed"} do |speed|
		@creatures.last.vector.speed.should == speed.to_f
	end
	
	Then /the creature's (?:angle|pitch) should be "([\d\.]+?)"/ do |attribute, pitch|
		@creature.vector.pitch.should == pitch.to_f
	end
	
	Then %Q{there should be "$object_count" objects in the environment} do |object_count|
		@environment.object_count.should == object_count
	end

	
end
