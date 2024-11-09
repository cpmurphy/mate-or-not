#!/usr/bin/env ruby
require 'json'
require 'pgn'

def analyze_mate_position(position)
  board = position.board.squares
  king_pos = find_king_position(board)
  checking_pieces = find_checking_pieces(board, king_pos)
  
  {
    blocking_squares: find_blocking_squares(board, king_pos, checking_pieces),
    capturable_checkers: find_capturable_checkers(board, king_pos, checking_pieces),
    removable_neighbors: find_removable_neighbors(board, king_pos, checking_pieces)
  }
end

def find_king_position(board)
  # Find the black or white king based on which side is to move
  board.each_with_index do |rank, rank_idx|
    rank.each_with_index do |piece, file_idx|
      if piece == 'k' || piece == 'K'
        return [file_idx, rank_idx]
      end
    end
  end
end

def find_checking_pieces(board, king_pos)
  checking = []
  king = board[king_pos[1]][king_pos[0]]
  is_white_king = king == 'K'
  
  board.each_with_index do |rank, rank_idx|
    rank.each_with_index do |piece, file_idx|
      next unless piece # Skip empty squares
      next if (piece == piece.upcase) == is_white_king # Skip pieces of same color as king
      
      pos = [file_idx, rank_idx]
      if is_attacking_king?(board, pos, king_pos)
        checking << {
          position: pos,
          piece: piece,
          distance: manhattan_distance(pos, king_pos)
        }
      end
    end
  end
  checking
end

def find_blocking_squares(board, king_pos, checking_pieces)
  return [] if checking_pieces.length > 1 # Can't block double check
  return [] if checking_pieces.empty?
  
  checker = checking_pieces.first
  return [] if manhattan_distance(checker[:position], king_pos) == 1 # Can't block adjacent check
  return [] if checker[:piece].downcase == 'n' # Can't block knight check
  
  squares_between(checker[:position], king_pos)
end

def find_capturable_checkers(board, king_pos, checking_pieces)
  return [] if checking_pieces.length > 1 # In double check, must move king
  return [] if checking_pieces.empty?
  
  checker = checking_pieces.first
  [checker[:position]] # The square where the checking piece could be captured
end

def find_removable_neighbors(board, king_pos, checking_pieces)
  removable = []
  king = board[king_pos[1]][king_pos[0]]
  is_white_king = king == 'K'
  
  # Check all adjacent squares
  [[-1,-1],[-1,0],[-1,1],[0,-1],[0,1],[1,-1],[1,0],[1,1]].each do |dx, dy|
    x, y = king_pos[0] + dx, king_pos[1] + dy
    next unless x.between?(0, 7) && y.between?(0, 7)
    
    piece = board[y][x]
    next unless piece # Skip empty squares
    next if (piece == piece.upcase) != is_white_king # Skip enemy pieces
    
    # Temporarily remove the piece
    board[y][x] = nil
    is_safe = !square_is_attacked?(board, [x, y], is_white_king)
    board[y][x] = piece # Restore the piece
    
    removable << [x, y] if is_safe
  end
  
  removable
end

def manhattan_distance(pos1, pos2)
  (pos1[0] - pos2[0]).abs + (pos1[1] - pos2[1]).abs
end

def is_attacking_king?(board, from_pos, king_pos)
  piece = board[from_pos[1]][from_pos[0]]
  case piece.downcase
  when 'p'
    pawn_attacking?(board, from_pos, king_pos)
  when 'n'
    knight_attacking?(from_pos, king_pos)
  when 'b'
    bishop_attacking?(board, from_pos, king_pos)
  when 'r'
    rook_attacking?(board, from_pos, king_pos)
  when 'q'
    queen_attacking?(board, from_pos, king_pos)
  when 'k'
    king_attacking?(from_pos, king_pos)
  end
end

def pawn_attacking?(board, from_pos, king_pos)
  # Determine pawn's color (white moves up, black moves down)
  is_white = board[from_pos[1]][from_pos[0]] == 'P'
  direction = is_white ? -1 : 1
  
  # Pawns attack diagonally
  attack_squares = [
    [from_pos[0] - 1, from_pos[1] + direction],
    [from_pos[0] + 1, from_pos[1] + direction]
  ]
  
  attack_squares.include?(king_pos)
end

def knight_attacking?(from_pos, king_pos)
  knight_moves = [
    [-2, -1], [-2, 1], [-1, -2], [-1, 2],
    [1, -2], [1, 2], [2, -1], [2, 1]
  ]
  
  knight_moves.any? do |move|
    [from_pos[0] + move[0], from_pos[1] + move[1]] == king_pos
  end
end

def bishop_attacking?(board, from_pos, king_pos)
  # Check if king is on a diagonal
  dx = (king_pos[0] - from_pos[0]).abs
  dy = (king_pos[1] - from_pos[1]).abs
  return false unless dx == dy
  
  # Check if path is clear
  ray_clear?(board, from_pos, king_pos)
end

def rook_attacking?(board, from_pos, king_pos)
  # Check if king is on same rank or file
  return false unless from_pos[0] == king_pos[0] || from_pos[1] == king_pos[1]
  
  # Check if path is clear
  ray_clear?(board, from_pos, king_pos)
end

def queen_attacking?(board, from_pos, king_pos)
  # Queen combines rook and bishop movements
  rook_attacking?(board, from_pos, king_pos) || bishop_attacking?(board, from_pos, king_pos)
end

def king_attacking?(from_pos, king_pos)
  # Kings attack adjacent squares
  dx = (king_pos[0] - from_pos[0]).abs
  dy = (king_pos[1] - from_pos[1]).abs
  dx <= 1 && dy <= 1
end

def ray_clear?(board, from_pos, king_pos)
  dx = king_pos[0] - from_pos[0]
  dy = king_pos[1] - from_pos[1]
  
  # Determine step direction
  step_x = dx == 0 ? 0 : dx / dx.abs
  step_y = dy == 0 ? 0 : dy / dy.abs
  
  # Check each square along the path (excluding start and end points)
  current_x = from_pos[0] + step_x
  current_y = from_pos[1] + step_y
  
  while [current_x, current_y] != king_pos
    return false if board[current_y][current_x] # Path is blocked
    current_x += step_x
    current_y += step_y
  end
  
  true
end

def squares_between(from_pos, to_pos)
  squares = []
  dx = to_pos[0] - from_pos[0]
  dy = to_pos[1] - from_pos[1]
  
  step_x = dx == 0 ? 0 : dx / dx.abs
  step_y = dy == 0 ? 0 : dy / dy.abs
  
  current_x = from_pos[0] + step_x
  current_y = from_pos[1] + step_y
  
  while [current_x, current_y] != to_pos
    squares << [current_x, current_y]
    current_x += step_x
    current_y += step_y
  end
  
  squares
end

def mate_position(game)
  # Check if the last move has a mate (#)
  last_move = game.moves.last
  return nil unless last_move && last_move.notation.include?('#')
  
  fen = game.positions.last.to_fen
  analysis = analyze_mate_position(game.positions.last)
  
  {
    fen: fen,
    analysis: analysis
  }
end

def square_is_attacked?(board, square, is_white_king)
  board.each_with_index do |rank, rank_idx|
    rank.each_with_index do |piece, file_idx|
      next unless piece # Skip empty squares
      next if (piece == piece.upcase) == is_white_king # Skip friendly pieces
      
      attacker_pos = [file_idx, rank_idx]
      return true if is_attacking_square?(board, attacker_pos, square)
    end
  end
  false
end

def is_attacking_square?(board, from_pos, target_square)
  piece = board[from_pos[1]][from_pos[0]]
  case piece.downcase
  when 'p'
    pawn_attacking?(board, from_pos, target_square)
  when 'n'
    knight_attacking?(from_pos, target_square)
  when 'b'
    bishop_attacking?(board, from_pos, target_square)
  when 'r'
    rook_attacking?(board, from_pos, target_square)
  when 'q'
    queen_attacking?(board, from_pos, target_square)
  when 'k'
    king_attacking?(from_pos, target_square)
  end
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
    if fen = mate_position(game)
      mate_positions << {
        from: "#{game.tags['White']} vs #{game.tags['Black']}, #{game.tags['Event']}, #{game.tags['Date'][0...4]}",
        fen: fen[:fen],
        analysis: fen[:analysis]
      }
    end
  end
end

puts JSON.pretty_generate(mate_positions) 
