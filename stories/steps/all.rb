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
load File.join(File.dirname(__FILE__), '..', 'lib', 'utility.rb')


include Zyps




steps_for(:all) do

	#TODO: This is a total kludge.
	Given /an environment/ do
		@om = ObjectManager.new
		@environment = @om.resolve_objects("an environment").first
		def add_to_environment(object)
			@environment << object
			object
		end
		@om.on_create("target") {add_to_environment Creature.new}
		@om.on_create("creature") {add_to_environment Creature.new}
		@om.on_create("game object") {add_to_environment GameObject.new}
	end

	Given /(an? (?:creature|game object|target|behavior|color|location|vector|clock))/ do |subject|
		@om.resolve_objects(subject)
	end
	Given /(an? (?:creature|game object|target|behavior|color|location|vector|clock)) with an? (.+?) of "(.+?)"/ do |subject, attribute_name, value|
		@om.resolve_objects(subject).each {|s| s.method("#{attribute_name}=").call(convert(value))}
	end
	Given /(an? (?:creature|game object|target|behavior|color|location|vector|clock)) with an? (.+?) of "(.+?)" and an? (.+?) of "(.+?)"/ do |subject, attribute1, value1, attribute2, value2|
		@om.resolve_objects(subject).each do |s|
			s.method("#{attribute1}=").call(convert(value1))
			s.method("#{attribute2}=").call(convert(value2))
		end
	end

	Given /(a (?:creature|game object|target)) whose location is "([\d\.]+)", "([\d\.]+)"/ do |subject, x, y|
		location = Location.new(x.to_f, y.to_f)
		@om.resolve_objects(subject).each do |s|
			s << location
		end
	end
	
	Given /(a creature|a game object) whose vector has a speed of "([\d\.]+)" and an? (?:angle|pitch) of "([\d\.]+)"/ do |subject, speed, pitch|
		vector = Vector.new(speed.to_f, pitch.to_f)
		@om.resolve_objects(subject).each do |s|
			s << vector
		end
	end
	
	Given /^an? (\w+?) (action|condition) (initialized )?with an? (\w+) of "(.+)?"/ do |name, type, use_constructor, attribute, value|
		#If attribute values are to be passed to constructor, do so.
		if use_constructor == "initialized "
			object = Object.const_get(name.capitalize + type.capitalize).new(convert(value))
		else
			object = Object.const_get(name.capitalize + type.capitalize).new
			object.method("#{attribute}=").call(convert(value))
		end
	end

	Given /^an? (\w+?) (action|condition) (initialized )?with an? (\w+) of "([\d\.]+)" and an? (\w+) of "([\d\.]+)"/ do |name, type, use_constructor, attribute1, value1, attribute2, value2|
		if use_constructor == "initialized "
			object = Object.const_get(name.capitalize + type.capitalize).new(convert(value1), convert(value2))
		else
			object = Object.const_get(name.capitalize + type.capitalize).new
			object.method(attribute1).call(convert(value1))
			object.method(attribute2).call(convert(value2))
		end
	end

	Given /(.+?) has a (.+?) value of "(.+?)"/ do |subject, attribute_name, value|
		@om.resolve_objects(subject).each {|s| s.method("#{attribute_name}=").call(convert(value))}
	end

	
	When /(.+?) (?:is|are) (?:added|assigned) to (.+?)/ do |subject, target|
		@om.resolve_objects(subject).each do |s|
			@om.resolve_objects(target).each do |t|
				t << s
			end
		end
	end

	When %Q{the environment interacts} do
		@om.resolve_objects('the environment').each {|s| s.interact}
	end
	
	When /"([\d\.]+)" seconds? elapses?/ do |seconds|
		#Monkey-patch Time to return the given number of seconds when Clock calls it.
		Time.class_eval "def to_f; #{seconds}; end"
	end

	
	Then /(.+?) should have an? (.+?) value of "(.+?)"/ do |subject, attribute_name, value|
		@om.resolve_objects(subject).each do |s|
			method_name = attribute_name.split(/\s+/).map{|w| w.downcase}.join('_')
			s.method(method_name).call.should == convert(value)
		end
	end
	
	Then /(\w+)\(\) should (not )?be called on (.+?)/ do |method, negative, subject|
		@om.resolve_objects(subject).each do |s|
			if negative != "not "
				s.should_receive(method.to_sym)
			else
				s.should_not_receive(method.to_sym)
			end
		end
	end
	
	Then /(.+?) should have a location of "([\d\.]+)", "([\d\.]+)"/ do |subject, x, y|
		@om.resolve_objects(subject).each {|s| s.location.should == Location.new(x.to_f, y.to_f)}
	end
	
	Then /(.+?) should have a vector with a speed of "([\d\.]+)" and an? (?:angle|pitch) of "([\d\.]+)"/ do |subject, speed, pitch|
		@om.resolve_objects(subject).each {|s| s.vector.should == Vector.new(speed.to_f, pitch.to_f)}
	end
	
	Then /display (.+?)/ do |subject|
		puts "", "-" * 60
		@om.resolve_objects(subject).each {|s| puts s.to_s}
		puts "-" * 60
	end

	
end
