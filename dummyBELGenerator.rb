#!/usr/bin/env ruby

documentString = ""

def breakln(str)
	str << "\n"
end

def emptyln(str)
	breakln(str)
	breakln(str)
end

documentString << 'SET DOCUMENT Name = "BEL document generated for parsing purposes by bel2bioc"'
breakln(documentString)
documentString << 'SET DOCUMENT Description = "Note: This is an automatically created BEL document with dummy definitions. It\'s not intended for usage outside of bel2bioc conversion."'

emptyln(documentString)

DF = "DEFINE NAMESPACE"
URL = 'AS URL "http://www.example.com/example.belns"'
nameSpaces = File.open("namespaces")
nameSpaces.each do |ns|
	documentString << "#{DF} #{ns.chomp!} #{URL}"
	breakln(documentString)
end

emptyln(documentString)

# ToDo: Appending statements as read by csvParser.rb

documentString << "## EOF"

puts documentString

