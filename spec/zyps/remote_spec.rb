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


require 'spec'
require 'zyps/remote'


include Zyps


describe EnvironmentServer do

	before(:each) do
	end
	
	it "sends objects that were already on server when a new client connects"
	it "sends new objects as they're added to server"
	it "has authority on object movement by default"
	it "does not have authority on object movement when assigned to client"
	it "has authority on object removal"
	it "keeps updating other clients if one disconnects"
	it "lets new clients connect and get world if others are already connected"
	it "doesn't send new object to client if a rule tells it not to"
	it "keeps telling client about object creation until client acknowledges it"
	it "allows forced disconnection of clients"
	it "sends an error to banned clients that attempt to join"
	
	it "assigns no AreaOfInterest to a client by default"
	it "updates a client with no AreaOfInterest on all objects"
	it "updates a client on all objects inside its AreaOfInterest"
	it "does not update a client on objects outside its AreaOfInterest"
	it "allows a client to have more than one AreaOfInterest"
	it "allows different clients to have a different AreaOfInterest"

end


describe EnvironmentClient do

	before(:each) do
	end
	
	it "should send objects that were already on client when it connects to a server"
	it "should send new objects as they're added to client"
	it "shouldn't send new object to server if a rule tells it not to"
	it "should keep telling server about object creation until server acknowledges it"

	it "assigns no AreaOfInterest to server by default"
	it "updates server with no AreaOfInterest on all objects"
	it "updates a client on all objects inside its AreaOfInterest"
	it "does not update a client on objects outside its AreaOfInterest"
	it "allows a client to have more than one AreaOfInterest"
	it "allows different clients to have a different AreaOfInterest"
	
end
