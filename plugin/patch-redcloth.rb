# Patch RedCloth in runtime:
#
# * Remove handling of -deleted- text: it's useless, clunky, and usually
# produces lots of problems with constructs such as "a - b - c"
#
# * Make em dash space-delimited.

class ::RedCloth < String
	QTAGS.reject! { |x| x[0] == '-' }
	GLYPHS.collect! { |x|
		x[1] = '\1 &#8212; ' if x[1] == '\1&#8212;'
		x
	}
end
