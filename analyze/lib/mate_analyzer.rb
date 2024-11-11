#!/usr/bin/env ruby
require 'json'
require 'pgn'

class MateAnalyzer
  def initialize(position)
    @position = position
  end

  def find_king_position
    board = @position.board
    # Find the black or white king based on which side is to move
    wanted_king = @position.player == :black ? 'k' : 'K'
    board.squares.each_with_index do |file, file_idx|
      file.each_with_index do |piece, rank_idx|
        if piece == wanted_king
          return [file_idx, rank_idx]
        end
      end
    end
    raise "No king found"
  end

  def find_checking_pieces(king_pos)
    board = @position.board
    checking = []
    king = board.squares[king_pos[0]][king_pos[1]]
    is_white_king = king == 'K'

    board.squares.each_with_index do |file, file_idx|
      file.each_with_index do |piece, rank_idx|
        next unless piece # Skip empty squares
        next if (piece == piece.upcase) == is_white_king # Skip pieces of same color as king

        pos = [file_idx, rank_idx]
        if is_attacking_king?(board.squares, pos, king_pos)
          checking << {
            position: pos,
            piece: piece,
            distance: square_distance(pos, king_pos)
          }
        end
      end
    end
    checking
  end

  def find_blocking_squares(checking_pieces, king_pos)
    return [] if checking_pieces.length > 1 # Can't block double check
    return [] if checking_pieces.empty?

    checker = checking_pieces.first
    return [] if square_distance(checker[:position], king_pos) == 1 # Can't block adjacent check
    return [] if checker[:piece].downcase == 'n' # Can't block knight check

    squares_between(checker[:position], king_pos)
  end

  def find_capturable_checkers(checking_pieces, king_pos)
    return [] if checking_pieces.length > 1 # In double check, must move king
    return [] if checking_pieces.empty?

    checker = checking_pieces.first
    [checker[:position]] # The square where the checking piece could be captured
  end

  def find_removable_neighbors(king_pos)
    board = @position.board
    removable = []
    king = board.at(king_pos[0], king_pos[1])
    is_white_king = king == 'K'

    adjacent_squares = [[-1,-1],[-1,0],[-1,1],[0,-1],[0,1],[1,-1],[1,0],[1,1]].map do |dx, dy|
      x, y = king_pos[0] + dx, king_pos[1] + dy
    end.select do |x, y|
      x.between?(0, 7) && y.between?(0, 7)
    end

    adjacent_squares.each do |x, y|
      piece = board.squares[x][y]
      next unless piece # Skip empty squares
      next if (piece == piece.upcase) != is_white_king # Skip enemy pieces

      unless is_pinned?([x, y], king_pos)
        removable << [x, y]
      end
    end
    removable
  end

  def square_distance(pos1, pos2)
    [
      (pos1[0] - pos2[0]).abs,
      (pos1[1] - pos2[1]).abs
    ].max
  end

  def is_attacking_king?(squares, from_pos, king_pos)
    piece = squares[from_pos[0]][from_pos[1]]
    case piece.downcase
    when 'p'
      pawn_attacking?(squares, from_pos, king_pos)
    when 'n'
      knight_attacking?(from_pos, king_pos)
    when 'b'
      bishop_attacking?(squares, from_pos, king_pos)
    when 'r'
      rook_attacking?(squares, from_pos, king_pos)
    when 'q'
      queen_attacking?(squares, from_pos, king_pos)
    when 'k'
      king_attacking?(from_pos, king_pos)
    end
  end

  def pawn_attacking?(squares, from_pos, king_pos)
    # Determine pawn's color (white moves up, black moves down)
    is_white = squares[from_pos[1]][from_pos[0]] == 'P'
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

    knight_moves.any? do |dx, dy|
      [from_pos[0] + dx, from_pos[1] + dy] == king_pos
    end
  end

  def bishop_attacking?(squares, from_pos, king_pos)
    # Check if king is on a diagonal
    dx = (king_pos[0] - from_pos[0]).abs
    dy = (king_pos[1] - from_pos[1]).abs
    return false unless dx == dy

    # Check if path is clear
    ray_clear?(squares, from_pos, king_pos)
  end

  def rook_attacking?(squares, from_pos, king_pos)
    # Check if king is on same rank or file
    return false unless from_pos[0] == king_pos[0] || from_pos[1] == king_pos[1]

    # Check if path is clear
    ray_clear?(squares, from_pos, king_pos)
  end

  def queen_attacking?(squares, from_pos, king_pos)
    # Queen combines rook and bishop movements
    rook_attacking?(squares, from_pos, king_pos) || bishop_attacking?(squares, from_pos, king_pos)
  end

  def king_attacking?(from_pos, king_pos)
    # Kings attack adjacent squares
    dx = (king_pos[0] - from_pos[0]).abs
    dy = (king_pos[1] - from_pos[1]).abs
    dx <= 1 && dy <= 1
  end

  def ray_clear?(squares, from_pos, king_pos)
    dx = king_pos[0] - from_pos[0]
    dy = king_pos[1] - from_pos[1]

    # Determine step direction
    step_x = dx == 0 ? 0 : dx / dx.abs
    step_y = dy == 0 ? 0 : dy / dy.abs

    # Check each square along the path (excluding start and end points)
    current_x = from_pos[0] + step_x
    current_y = from_pos[1] + step_y

    while [current_x, current_y] != king_pos
      return false if squares[current_x][current_y] # Path is blocked
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

  def analyze_mate_position
    king_pos = find_king_position
    checking_pieces = find_checking_pieces(king_pos)

    {
      blocking_squares: find_blocking_squares(checking_pieces, king_pos),
      capturable_checkers: find_capturable_checkers(checking_pieces, king_pos),
      removable_neighbors: find_removable_neighbors(king_pos)
    }
  end

  def build_analysis
    analysis = analyze_mate_position

    result = {
      mate: @position.to_fen.to_s,
      analysis: analysis
    }
    result
  end

  def create_fen_from_board(board, position)
    PGN::Position.new(
      board,
      position.player,
      position.castling,
      position.en_passant,
      position.halfmove,
      position.fullmove
    ).to_fen
  end

  def to_algebraic(x, y)
    puts "x is not an integer, it is a #{x.class} with the value #{x}" unless x.is_a?(Integer)
    puts "y is not an integer, it is a #{y.class} with the value #{y}" unless y.is_a?(Integer)
    file = ('a'..'h').to_a[x]
    rank = y + 1
    "#{file}#{rank}"
  end

  def is_pinned?(piece_pos, king_pos)
    piece = @position.board.squares[piece_pos[0]][piece_pos[1]]
    return false unless piece # Empty square can't be pinned
    is_white = piece == piece.upcase

    # Check for potential pinning pieces (queens, rooks, bishops)
    @position.board.squares.each_with_index do |rank, rank_idx|
      rank.each_with_index do |potential_pinner, file_idx|
        next unless potential_pinner # Skip empty squares
        next if (potential_pinner == potential_pinner.upcase) == is_white # Skip friendly pieces

        pinner_pos = [rank_idx, file_idx]

        # Skip if not a sliding piece
        next unless ['q', 'r', 'b'].include?(potential_pinner.downcase)

        # Check if all three pieces are aligned
        if pieces_aligned?(pinner_pos, piece_pos, king_pos)
          # Check if piece is between king and pinner
          if between_points?(piece_pos, pinner_pos, king_pos)
            # Check if there are no other pieces between
            if no_pieces_between?(pinner_pos, piece_pos) &&
               no_pieces_between?(piece_pos, king_pos)
              return true
            end
          end
        end
      end
    end
    false
  end

  private

  def pieces_aligned?(pos1, pos2, pos3)
    # Check if three points are on same rank, file, or diagonal
    same_rank = pos1[0] == pos2[0] && pos2[0] == pos3[0]
    same_file = pos1[1] == pos2[1] && pos2[1] == pos3[1]
    same_diagonal = (pos1[0] - pos2[0]).abs == (pos1[1] - pos2[1]).abs &&
                   (pos2[0] - pos3[0]).abs == (pos2[1] - pos3[1]).abs &&
                   (pos1[0] - pos3[0]).abs == (pos1[1] - pos3[1]).abs

    same_rank || same_file || same_diagonal
  end

  def between_points?(test_point, point1, point2)
    # Check if test_point is between point1 and point2
    [test_point[0].between?(point1[0], point2[0]) || test_point[0].between?(point2[0], point1[0]),
     test_point[1].between?(point1[1], point2[1]) || test_point[1].between?(point2[1], point1[1])].all?
  end

  def no_pieces_between?(from_pos, to_pos)
    dx = to_pos[0] <=> from_pos[0]
    dy = to_pos[1] <=> from_pos[1]

    current_pos = [from_pos[0] + dx, from_pos[1] + dy]
    while current_pos != to_pos
      return false if @position.board.squares[current_pos[0]][current_pos[1]]
      current_pos[0] += dx
      current_pos[1] += dy
    end
    true
  end

end
