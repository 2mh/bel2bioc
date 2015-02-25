#!/usr/bin/env ruby

require 'csv'
require 'ostruct'

unless ARGV[0].nil?
	arg0 = ARGV[0]
else
	arg0 = "temp_data/DevelopmentSetTask1.csv"
end

csvTable = CSV.read(arg0, {col_sep:"\t", quote_char:"¬", headers:true})
rowArray = []
belArray = []

csvTable.each do |row|
	current = OpenStruct.new()
	current.bel_id = row[0]
	current.bel = row[1]
	current.sentence = row[3]
	rowArray << current
	belArray << row[1]
end

rowArrayEnum = rowArray.each

puts belArray

require 'pry'; binding.pry

# Pry session: type `rowArrayEnum.next` to enumerate

# cursor = rowArrayEnum.next
# puts cursor.bel_id
# puts cursor.sentence
