#!/usr/bin/env ruby
require 'json'
require 'pgn'
require_relative 'lib/mate_analyzer'

def mate_position(game)
  # Check if the last move has a mate (#)
  last_move = game.moves.last
  return nil unless last_move && last_move.notation.include?('#')

  game.positions.last
end

if ARGV.empty?
  puts "Usage: #{$0} pgn_file1 [pgn_file2 ...]"
  exit 1
end

mate_positions = []

ARGV.each do |filename|
  pgn_content = File.read(filename)
  games = PGN.parse(pgn_content)

  games.each do |game|
    if position = mate_position(game)
      analyzer = MateAnalyzer.new(position)
      mate_positions << analyzer.build_analysis
    end
  end
end

puts JSON.pretty_generate(mate_positions)
