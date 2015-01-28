require 'bel'
require 'simple_bioc'

ARGV.each do|infile|
	#belstr = IO.readlines("resources/knowledge/small_corpus.bel")
	#belfile = File.new("resources/knowledge/small_corpus.bel", "r")
	belfile = File.new(infile, "r")
	
	# parse; yield each parsed object to the block
	namespace_mapping = {GO:GOBP}
	BEL::Script.parse(belfile, namespace_mapping) do |obj|
	  puts "#{obj.class} #{obj}"
	end
end
