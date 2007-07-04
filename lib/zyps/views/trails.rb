#A view of game objects.
class TrailsView

	attr_reader :canvas, :width, :height
	attr_accessor :trail_length, :trail_width

	def initialize (width = 600, height = 400, trail_length = 5, trail_width = trail_length)
	
		@width, @height, @trail_length, @trail_width, @background = width, height, trail_length, trail_width
	
		#Create a drawing area.
		@canvas = Gtk::DrawingArea.new
		#Set to correct size.
		resize
		
		#Whenever the drawing area needs updating...
		@canvas.signal_connect("expose_event") do
			#Copy buffer bitmap to canvas.
			@canvas.window.draw_drawable(
				@canvas.style.fg_gc(@canvas.state), #Gdk::GC (graphics context) to use when drawing.
				buffer, #Gdk::Drawable source to copy onto canvas.
				0, 0, #Pull from upper left of source.
				0, 0, #Copy to upper left of canvas.
				-1, -1 #-1 width and height signals to copy entire source over.
			)
		end
		
		#Track a list of locations for each object.
		@locations = Hash.new {|h, k| h[k] = Array.new}
		
	end
	
	def width= (pixels)
		@width = pixels
		resize
	end
	def height= (pixels)
		@height = pixels
		resize
	end
	
	#Draw the objects.
	def render(objects)
		#Clear the background on the buffer.
		graphics_context = Gdk::GC.new(buffer)
		graphics_context.rgb_fg_color = Gdk::Color.new(0, 0, 0)
		buffer.draw_rectangle(
			graphics_context,
			true, #Filled.
			0, 0, #Upper-left corner.
			@width, @height #Lower-right corner.
		)
		#For each GameObject in the environment:
		objects.each do |object|
			#Add the object's current location to the list.
			@locations[object] << [object.location.x, object.location.y]
			#If the list is larger than the number of tail segments, delete the first position.
			@locations[object].shift if @locations[object].length > @trail_length
			#For each location in this object's list:
			@locations[object].each_with_index do |location, index|
				#Skip first location.
				next if index == 0
				#Divide the current segment number by trail segment count to get the multiplier to use for brightness and width.
				multiplier = index.to_f / @locations[object].length.to_f
				#Set the drawing color to use the object's colors, adjusted by the multiplier.
				graphics_context.rgb_fg_color = Gdk::Color.new( #Don't use Gdk::GC.foreground= here, as that requires a color to be in the color map already.
					object.color.red * multiplier * 65535,
					object.color.green * multiplier * 65535,
					object.color.blue * multiplier * 65535
				)
				#Multiply the actual drawing width by the current multiplier to get the current drawing width.
				graphics_context.set_line_attributes(
					(@trail_width * multiplier).ceil,
					Gdk::GC::LINE_SOLID,
					Gdk::GC::CAP_ROUND, #Line ends drawn as semicircles.
					Gdk::GC::JOIN_MITER #Only used for polygons.
				)
				#Get previous location so we can draw a line from it.
				previous_location = @locations[object][index - 1]
				#Draw a line with the current width from the prior location to the current location.
				buffer.draw_line(
					graphics_context,
					previous_location[0], previous_location[1],
					location[0], location[1]
				)
			end
		end
		@canvas.queue_draw_area(0, 0, @width, @height)
	end
	
	private
	
		def resize
			@canvas.set_size_request(@width, @height)
			@buffer = nil #Causes buffer to reset its size next time it's accessed.
		end
		
		def buffer
			@buffer ||= Gdk::Pixmap.new(@canvas.window, @width, @height, -1)
		end
	
end