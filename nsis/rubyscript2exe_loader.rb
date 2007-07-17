require 'rubyscript2exe'
require 'fileutils'
require 'pathname'

#Get path to RubyScript2Exe runtime temp directory.
p0 = Pathname.new(RUBYSCRIPT2EXE.appdir)
root_runtime = p0.parent.to_s

#We will not have a console, so log to a file.
$stdout = $stderr = File.new("#{root_runtime}/application.log", "w")

#Copy dependencies to runtime temp folder.
begin
    FileUtils.cp_r('dlls/.', root_runtime)
rescue
end

#Run main program.
load "../bin/zyps.rb"
