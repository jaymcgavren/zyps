== Synopsis

Zyps - A simulation/game with autonomous creatures.


== Description

Zyps are small creatures with minds of their own. You can create dozens of Zyps, then decide how each will act. (Will it run away from the others? Follow them? Eat them for lunch?) You can combine rules and actions to create very complex behaviors.


== Installation

  * Windows (without Ruby): Visit the project site (see below), download and run the Windows installer.  All the needed libraries are included.

  * With Ruby: {{{gem install zyps}}}
  
    * Ruby-GNOME2 is required, so visit its link below for download and installation instructions.


== Usage

If you used the Windows installer, Zyps should appear under the Start menu.

If you installed the Ruby gem, simply run "zyps" at a command line.


== API

Check the project site for API documentation.  Also see the "test" subfolder for sample code.


== Building from Source

The setup should be fairly standard for anyone familiar with Rake.  There are a few external dependencies; see below for links.

Get the source from the project site.

Change into the project directory.  Run "rake -T" for a list of targets.  Ruby-GNOME2 is required for the GUI.  You'll need RubyScript2Exe to build a Windows executable, or NSIS to build a Windows installer.  Building a gem should work out of the box.


== See Also

Project Site: http://code.google.com/p/itunes-control/

Ruby-GNOME2: http://ruby-gnome2.sourceforge.jp/

Nullsoft Scriptable Install System: http://nsis.sourceforge.net/

RubyScript2Exe: http://www.erikveen.dds.nl/rubyscript2exe/index.html


== Thanks

NullSoft Scriptable Install System is used to make the Windows installer; thanks to its authors.

RubyScript2Exe is used to make the Windows executable; thanks to Erik Veenstra for pulling off this seemingly impossible feat!

The GUI is provided via Ruby-GNOME2.  Thanks to its authors for their considerable effort in making the library (relatively) easy to use.


== Author

Copyright Jay McGavren, jay@mcgavren.com


== License

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation; either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
