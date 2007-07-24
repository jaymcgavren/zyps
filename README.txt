== Synopsis

Zyps - A simulation/game with autonomous creatures.


== Description

Zyps are small creatures with minds of their own.  You can create dozens of Zyps, then decide how each will act.  (Will it run away from the others?  Follow them?  Eat them for lunch?)  You can combine rules and actions to create very complex behaviors.


== Requirements

* Ruby: http://www.ruby-lang.org
* Ruby-GNOME2: http://ruby-gnome2.sourceforge.jp
* Rake (to build from source): http://rake.rubyforge.org


== Installation

Make sure you have administrative privileges, then type the following at a command line:

	gem install zyps


== Usage

Ensure Ruby-GNOME2 is installed and working.

To see the demo, at a command line, type:

	zyps_demo


== Development

Source code and documentation are available via the project site (http://jay.mcgavren.com/zyps).

Once downloaded, change into the project directory.  For a list of targets, run:

	rake -T

To build a gem:

	rake

To see the demo:
	
	rake demo

To create a "doc" subdirectory with API documentation:

	rake rdoc

Also see "bin/zyps_demo" and the "test" subfolder in the project directory for sample code.


== Thanks

The GUI is provided via Ruby-GNOME2.  Thanks to its authors for their considerable effort in making their library easy to use.


== Author

Copyright 2007 Jay McGavren, jay@mcgavren.com


== License

Zyps is free software; you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation; either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
