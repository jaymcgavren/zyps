#!/usr/bin/ruby -w

require 'rubygems'
require 'rake/gempackagetask'
require 'rake/clean'
require 'rake/rdoctask'
require 'rake/testtask'


#Configuration variables.
PRODUCT_NAME = "Zyps"
SUMMARY = "A simulation/game with autonomous creatures."
RELEASE_VERSION = ENV["#{PRODUCT_NAME.upcase}_VERSION"] or raise "#{PRODUCT_NAME.upcase}_VERSION environment variable not defined."
AUTHOR = "Jay McGavren"
AUTHOR_EMAIL = "jay@mcgavren.com"
WEB_SITE = "http://jay.mcgavren.com/#{PRODUCT_NAME.downcase}/"
REQUIREMENTS = [
	"Ruby-GNOME2"
]

#Get locations of compilers and libraries.
RUBYSCRIPT2EXE = ENV["RUBYSCRIPT2EXE"] || File.join(Config::CONFIG["bindir"], "rubyscript2exe")
MAKENSIS = ENV["MAKENSIS"] || File.join(ENV["ProgramFiles"], "nsis", "makensis.exe")
GTK_HOME = ENV["GTK_HOME"] || File.join(ENV["RUBY_HOME"], "lib", "GTK")
DLLS = %w{
	bin
	bin/libatk-1.0-0.dll
	bin/libcairo-2.dll
	bin/libfreetype-6.dll
	bin/libgdk-win32-2.0-0.dll
	bin/libgdk_pixbuf-2.0-0.dll
	bin/libglib-2.0-0.dll
	bin/libgobject-2.0-0.dll
	bin/libgtk-win32-2.0-0.dll
	bin/libpango-1.0-0.dll
	bin/libpangocairo-1.0-0.dll
	bin/libpangoft2-1.0-0.dll
	bin/libpangowin32-1.0-0.dll
	etc
	etc/gtk-2.0
	etc/gtk-2.0/gtkrc
	lib
	lib/charset.alias
	lib/glib-2.0
	lib/glib-2.0/include
	lib/glib-2.0/include/glibconfig.h
	lib/gtk-2.0
	lib/gtk-2.0/2.10.0
	lib/gtk-2.0/2.10.0/engines
	lib/gtk-2.0/2.10.0/engines/libwimp.dll
	lib/gtk-2.0/2.4.0
	lib/gtk-2.0/2.4.0/engines
	lib/gtk-2.0/2.4.0/engines/libmetal.dll
	lib/gtk-2.0/2.4.0/engines/libredmond95.dll
	lib/gtk-2.0/include
	lib/gtk-2.0/include/gdkconfig.h
	lib/gtkglext-1.0
	lib/gtkglext-1.0/include
	lib/gtkglext-1.0/include/gdkglext-config.h
	lib/xml2Conf.sh
	share
	share/themes
	share/themes/Default
	share/themes/Default/gtk-2.0-key
	share/themes/Default/gtk-2.0-key/gtkrc
	share/themes/MS-Windows
	share/themes/MS-Windows/gtk-2.0
	share/themes/MS-Windows/gtk-2.0/gtkrc
	share/themes/Redmond95
	share/themes/Redmond95/gtk-2.0
	share/themes/Redmond95/gtk-2.0/gtkrc
}

#Set up rdoc.
RDOC_OPTIONS = [
	"--title", PRODUCT_NAME,
	"--main", "README.txt"
]

#Get file names.
EXECUTABLE = "bin/#{PRODUCT_NAME.downcase}"
RUBYSCRIPT2EXE_LOADER = "nsis/rubyscript2exe_loader.rb"
WINDOWS_EXECUTABLE = "build/#{PRODUCT_NAME.downcase}.exe"
WINDOWS_INSTALLER = "pkg/#{PRODUCT_NAME.downcase}-setup-#{RELEASE_VERSION}.exe"
NSIS_SCRIPT = "nsis/#{PRODUCT_NAME.downcase}.nsi"


desc "Set up directories"
task :setup => ["build", "pkg", "dlls"]

desc "Create an executable"
task :compile => :setup
task :compile => :copy_dlls
task :compile => WINDOWS_EXECUTABLE

desc "Create a distributable"
task :distribute => :compile
task :distribute => WINDOWS_INSTALLER

desc "Create a gem by default"
task :default => [:test, :gem]


directory "build"
directory "pkg"
directory "dlls"

desc "Copy libraries to DLL folder"
task :copy_dlls => [:setup] do
	DLLS.each do |file|
		source_path = File.join(GTK_HOME, file)
		destination_path = File.join("dlls", file)
		if File.directory?(source_path) then
			mkdir_p(destination_path)
		else
			cp(source_path, destination_path)
		end
	end
end


desc "Compile a Windows executable"
file WINDOWS_EXECUTABLE => [EXECUTABLE] do |target|
	#Ensure rubyscript2exe is installed.
	unless File.exist?(RUBYSCRIPT2EXE)
		raise "Cannot find rubyscript2exe.  Set RUBYSCRIPT2EXE environment variable to full path of rubyscript2exe, and run again."
	end
	#Compile an executable.
	system %{ruby -I lib #{RUBYSCRIPT2EXE} --rubyscript2exe-rubyw #{target.prerequisites.join(" ")}}
	#Move executable to target location, as it is always placed in current directory.
	mv "#{PRODUCT_NAME.downcase}.exe", target.name
end


desc "Create a NSIS installer"
file WINDOWS_INSTALLER => [WINDOWS_EXECUTABLE, NSIS_SCRIPT] do |target|
	#Ensure NSIS is installed.
	unless File.exist?(MAKENSIS)
		raise "Cannot find makensis.  Set MAKENSIS environment variable to full path of makensis, and run again."
	end
	#Run the installer creation script.
	system [
		MAKENSIS,
		"/V2", #Surpress info messages.
		"/Obuild/nsis.log", #Log compiler output instead of outputting to STDOUT.
		"/NOCD", #Do not CD to NSI script directory before running.
		"/DPRODUCT_VERSION=#{RELEASE_VERSION}", #Define in-NSI-script variables.
		"/DPRODUCT_PUBLISHER=#{AUTHOR}",
		"/DPRODUCT_WEB_SITE=#{WEB_SITE}",
		"/XOutFile #{target.name}",
		NSIS_SCRIPT #Script to run.
	].map{|v| %("#{v}")}.join(" ")
end


desc "Create documentation"
Rake::RDocTask.new do |rdoc|
	rdoc.rdoc_dir = "doc"
	rdoc.rdoc_files = FileList[
		"lib/**/*",
		"*.txt"
	].exclude(/\bsvn\b/).to_a
	rdoc.options = RDOC_OPTIONS
end


desc "Test the package"
Rake::TestTask.new do |test|
	test.libs << "lib"
	test.test_files = FileList["test/test_*.rb"]
end


desc "Package a gem"
specification = Gem::Specification.new do |spec|
	spec.name = PRODUCT_NAME.downcase
	spec.version = RELEASE_VERSION
	spec.author = AUTHOR
	spec.email = AUTHOR_EMAIL
	spec.homepage = WEB_SITE
	spec.platform = Gem::Platform::RUBY
	spec.summary = SUMMARY
	spec.requirements << REQUIREMENTS
	spec.rubyforge_project = PRODUCT_NAME.downcase
	spec.require_path = "lib"
	spec.autorequire = PRODUCT_NAME.downcase
	spec.test_files = Dir.glob("test/test_*.rb")
	spec.has_rdoc = true
	spec.rdoc_options = RDOC_OPTIONS
	spec.extra_rdoc_files = ["README.txt", "COPYING.LESSER.txt", "COPYING.txt"]
	spec.files = FileList[
		"*.txt",
		"bin/**/*",
		"lib/**/*",
		"test/**/*",
		"doc/**/*"
	].exclude(/\bsvn\b/).to_a
	spec.executables << PRODUCT_NAME.downcase
end
Rake::GemPackageTask.new(specification) do |package|
	package.need_tar = true
end


CLEAN.include(%W{build})
CLOBBER.include(%W{pkg doc dlls})
