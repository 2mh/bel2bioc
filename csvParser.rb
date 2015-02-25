#!/usr/bin/env ruby

require 'csv'
require 'ostruct'

ARGV[0] = "../Task1/DevelopmentSetTask1.txt"


csvTable = CSV.read(ARGV[0], {col_sep:"\t", quote_char:"¬", headers:true})
rowArray = []

csvTable.each do |row|
	current = OpenStruct.new()
	current.bel_id = row[0]
	current.sentence = row[3]
	rowArray << current
end

rowArrayEnum = rowArray.each

require 'pry'; binding.pry

#cursor = rowArrayEnum.next
#puts cursor.bel_id
#puts cursor.sentence
