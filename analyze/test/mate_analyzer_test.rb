require 'minitest/autorun'
require_relative '../lib/mate_analyzer'
require 'pgn'
require 'debug'

class MateAnalyzerTest < Minitest::Test
  def test_find_king_position_white_king
    # Create a board with the kings on their home squares
    board = PGN::Board.new([
      [nil, nil, nil, nil, nil, nil, nil, nil],
      [nil, nil, nil, nil, nil, nil, nil, nil],
      [nil, nil, nil, nil, nil, nil, nil, nil],
      [nil, nil, nil, nil, nil, nil, nil, nil],
      ["K", nil, nil, nil, nil, nil, nil, "k"],
      [nil, nil, nil, nil, nil, nil, nil, nil],
      [nil, nil, nil, nil, nil, nil, nil, nil],
      [nil, nil, nil, nil, nil, nil, nil, nil]
    ])

    position = PGN::Position.new(board, :white)
    analyzer = MateAnalyzer.new(position)
    assert_equal "K", board.at(4, 0)
    assert_equal "K", board.at("e1")
    assert_equal [4, 0], analyzer.find_king_position

    position2 = PGN::Position.new(board, :black)
    analyzer = MateAnalyzer.new(position2)
    assert_equal "k", board.at(4, 7)
    assert_equal "k", board.at("e8")
    assert_equal [4, 7], analyzer.find_king_position
  end

  def test_find_king_position_complex_position
    # Create a more complex board with pieces around the king
    fen = PGN::FEN.new("rn3rk1/p4ppp/1p1n4/2p5/2R5/P3PN2/1B1PKPPP/R7 w - - 1 17")
    position = fen.to_position
    analyzer = MateAnalyzer.new(position)
    assert_equal "K", position.board.at(4, 1)
    assert_equal "K", position.board.at("e2")
    assert_equal [4, 1], analyzer.find_king_position
  end

  def test_find_king_position_no_king
    fen = PGN::FEN.new("8/8/8/8/8/8/8/8 w - - 0 1")
    position = fen.to_position
    analyzer = MateAnalyzer.new(position)
    assert_raises "No king found" do
      analyzer.find_king_position
    end
  end

  def test_find_checking_pieces_single_pawn
    fen = PGN::FEN.new("8/3R3N/3Q4/5k2/4p1P1/6K1/8/8 b - - 0 60")
    position = fen.to_position
    analyzer = MateAnalyzer.new(position)
    assert_equal "k", position.board.at(5, 4)
    assert_equal "k", position.board.at("f5")
    assert_equal "P", position.board.at(6, 3)
    assert_equal "P", position.board.at("g4")
    assert_equal [
      {
        position: [6, 3],
        piece: "P",
        distance: 1
      }
    ], analyzer.find_checking_pieces([5, 4])
  end

  def test_find_checking_pieces_single_knight
    fen = PGN::FEN.new("r1bkr3/ppppnNbp/8/6B1/2Bp3P/2P5/PP2q1P1/6KR b - - 1 20")
    position = fen.to_position
    analyzer = MateAnalyzer.new(position)
    assert_equal "k", position.board.at(3, 7)
    assert_equal "k", position.board.at("d8")
    assert_equal "N", position.board.at(5, 6)
    assert_equal "N", position.board.at("f7")
    assert_equal [
      {
        position: [5, 6],
        piece: "N",
        distance: 2
      }
    ], analyzer.find_checking_pieces([3, 7])
  end

  def test_find_checking_pieces_single_bishop
    fen = PGN::FEN.new("8/8/b7/8/3q4/4Pk2/3P4/5K2 w - - 0 20")
    position = fen.to_position
    analyzer = MateAnalyzer.new(position)
    assert_equal "K", position.board.at(5, 0)
    assert_equal "K", position.board.at("f1")
    assert_equal "b", position.board.at(0, 5)
    assert_equal "b", position.board.at("a6")
    assert_equal [
      {
        position: [0, 5],
        piece: "b",
        distance: 5
      }
    ], analyzer.find_checking_pieces([5, 0])
  end

  def test_find_checking_pieces_single_rook
    fen = PGN::FEN.new("8/1q6/8/5k2/8/8/6P1/3r2K1 w - - 0 60")
    position = fen.to_position
    analyzer = MateAnalyzer.new(position)
    assert_equal "K", position.board.at(6, 0)
    assert_equal "K", position.board.at("g1")
    assert_equal "r", position.board.at(3, 0)
    assert_equal "r", position.board.at("d1")
    assert_equal [
      {
        position: [3, 0],
        piece: "r",
        distance: 3
      }
    ], analyzer.find_checking_pieces([6, 0])
  end

  def test_find_checking_pieces_double_check_bishop_and_rook
    fen = PGN::FEN.new("1r4k1/6P1/5PK1/8/6r1/3b4/8/8 w - - 0 20")
    position = fen.to_position
    analyzer = MateAnalyzer.new(position)
    assert_equal "K", position.board.at(6, 5)
    assert_equal "K", position.board.at("g6")
    assert_equal "r", position.board.at(6, 3)
    assert_equal "r", position.board.at("g4")
    assert_equal "b", position.board.at(3, 2)
    assert_equal "b", position.board.at("d3")
    assert_equal [
      {
        position: [3, 2],
        piece: "b",
        distance: 3
      },
      {
        position: [6, 3],
        piece: "r",
        distance: 2
      }
    ], analyzer.find_checking_pieces([6, 5]).sort_by { |p| p[:piece] }
  end

  def test_find_checking_pieces_double_check_knight_and_rook
    fen = PGN::FEN.new("q3r1k1/8/8/8/8/5nP1/5P2/4K3 w - - 0 30")
    position = fen.to_position
    analyzer = MateAnalyzer.new(position)
    assert_equal "K", position.board.at(4, 0)
    assert_equal "K", position.board.at("e1")
    assert_equal "n", position.board.at(5, 2)
    assert_equal "n", position.board.at("f3")
    assert_equal "r", position.board.at(4, 7)
    assert_equal "r", position.board.at("e8")
    assert_equal [
      {
        position: [5, 2],
        piece: "n",
        distance: 2
      },
      {
        position: [4, 7],
        piece: "r",
        distance: 7
      }
    ], analyzer.find_checking_pieces([4, 0]).sort_by { |p| p[:piece] }
  end

  def test_find_checking_pieces_multiple_checkers_blocked
    fen = PGN::FEN.new("8/3R3N/3Q4/5k2/4p1P1/6K1/8/1B6 b - - 0 60")
    position = fen.to_position
    analyzer = MateAnalyzer.new(position)
    assert_equal "k", position.board.at(5, 4)
    assert_equal "k", position.board.at("f5")
    assert_equal "P", position.board.at(6, 3)
    assert_equal "P", position.board.at("g4")
    assert_equal [
      {
        position: [6, 3],
        piece: "P",
        distance: 1
      }
    ], analyzer.find_checking_pieces([5, 4])
  end

  def test_find_blocking_squares_back_diagonal
    fen = PGN::FEN.new("8/1p2k3/pK4Pr/8/1P6/P7/5q2/8 w - - 0 60")
    position = fen.to_position
    analyzer = MateAnalyzer.new(position)
    assert_equal "K", position.board.at(1, 5)
    assert_equal "K", position.board.at("b6")
    assert_equal "q", position.board.at(5, 1)
    assert_equal "q", position.board.at("f2")
    assert_equal [[2, 4], [3, 3], [4, 2]],
      analyzer.find_blocking_squares(
        [{ position: [1, 5], piece: "q", distance: 4}],
        [5, 1]
    )
  end

  def test_find_blocking_squares_backward_file
    fen = PGN::FEN.new("5R2/1p6/p1q3Pr/8/1P6/P7/1KQ1pk2/8 b - - 0 60")
    position = fen.to_position
    analyzer = MateAnalyzer.new(position)
    assert_equal "k", position.board.at(5, 1)
    assert_equal "k", position.board.at("f2")
    assert_equal "R", position.board.at(5, 7)
    assert_equal "R", position.board.at("f8")
    assert_equal [[5, 6], [5, 5], [5, 4], [5, 3], [5, 2]],
      analyzer.find_blocking_squares(
        [{ position: [5, 7], piece: "r", distance: 6}],
        [5, 1]
    )
  end

  def test_find_capturable_checkers_single_queen
    fen = PGN::FEN.new("5R2/1p6/p1q3Pr/2Q5/1P6/P4p2/1K3k2/8 b - - 0 60")
    position = fen.to_position
    analyzer = MateAnalyzer.new(position)
    assert_equal [[2, 4]],
      analyzer.find_capturable_checkers(
        [{ position: [2, 4], piece: "Q", distance: 3}],
        [5, 1]
      )
  end

  def test_find_capturable_checkers_single_rook
    fen = PGN::FEN.new("r3rkR1/1p1b3Q/8/pP1nq1p1/P1p5/4P3/3PN1PP/R5K1 b - - 7 31")
    position = fen.to_position
    analyzer = MateAnalyzer.new(position)
    assert_equal "k", position.board.at(5, 7)
    assert_equal "k", position.board.at("f8")
    assert_equal "R", position.board.at(6, 7)
    assert_equal "R", position.board.at("g8")
    assert_equal [[6, 7]],
      analyzer.find_capturable_checkers(
        [{ position: [6, 7], piece: "R", distance: 1}],
        [5, 7]
      )
  end

  def test_find_capturable_checkers_multiple_checkers
    fen = PGN::FEN.new("8/1p6/p5P1/2Q5/1P3k2/P1R1np2/2K4r/8 w - - 0 60")
    position = fen.to_position
    analyzer = MateAnalyzer.new(position)
    assert_equal "K", position.board.at(2, 1)
    assert_equal "K", position.board.at("c2")
    assert_equal "n", position.board.at(4, 2)
    assert_equal "n", position.board.at("e3")
    assert_equal "r", position.board.at(7, 1)
    assert_equal "r", position.board.at("h2")
    assert_equal [],
      analyzer.find_capturable_checkers(
        [{ position: [4, 2], piece: "n", distance: 2},
         { position: [7, 1], piece: "r", distance: 5}],
        [2, 1]
      )
  end


  def test_is_pinned_by_rook
    # Position with white rook pinning black bishop to black king
    # d8 = [3,0], d6 = [3,2], d5 = [3,3]
    board = PGN::Board.new([
      [nil, nil, nil, "k", nil, nil, nil, nil],
      [nil, nil, nil, nil, nil, nil, nil, nil],
      [nil, nil, nil, "b", nil, nil, nil, nil],
      [nil, nil, nil, "R", nil, nil, nil, nil],
      [nil, nil, nil, nil, nil, nil, nil, nil],
      [nil, nil, nil, nil, nil, nil, nil, nil],
      [nil, nil, nil, nil, nil, nil, nil, nil],
      [nil, nil, nil, nil, nil, nil, nil, nil]
    ].transpose)

    position = PGN::Position.new(board, :black)
    analyzer = MateAnalyzer.new(position)
    assert analyzer.is_pinned?([3,2], [3,0]) # bishop on d6 pinned to king on d8
  end

  def test_is_pinned_by_bishop
    # Position with white bishop pinning black knight to black king
    # f8 = [5,0], e7 = [4,1], d6 = [3,2]
    board = PGN::Board.new([
      [nil, nil, nil, nil, nil, "k", nil, nil],
      [nil, nil, nil, nil, "n", nil, nil, nil],
      [nil, nil, nil, "B", nil, nil, nil, nil],
      [nil, nil, nil, nil, nil, nil, nil, nil],
      [nil, nil, nil, nil, nil, nil, nil, nil],
      [nil, nil, nil, nil, nil, nil, nil, nil],
      [nil, nil, nil, nil, nil, nil, nil, nil],
      [nil, nil, nil, nil, nil, nil, nil, nil]
    ].transpose)

    position = PGN::Position.new(board, :black)
    analyzer = MateAnalyzer.new(position)
    assert analyzer.is_pinned?([4,1], [5,0]) # knight on e7 pinned to king on f8
  end

  def test_is_pinned_by_queen
    # Position with white queen pinning black rook to black king
    # b8 = [1,0], b7 = [1,1], b6 = [1,2]
    board = PGN::Board.new([
      [nil, "k", nil, nil, nil, nil, nil, nil],
      [nil, "r", nil, nil, nil, nil, nil, nil],
      [nil, "Q", nil, nil, nil, nil, nil, nil],
      [nil, nil, nil, nil, nil, nil, nil, nil],
      [nil, nil, nil, nil, nil, nil, nil, nil],
      [nil, nil, nil, nil, nil, nil, nil, nil],
      [nil, nil, nil, nil, nil, nil, nil, nil],
      [nil, nil, nil, nil, nil, nil, nil, nil]
    ].transpose)

    position = PGN::Position.new(board, :black)
    analyzer = MateAnalyzer.new(position)
    assert analyzer.is_pinned?([1,1], [1,0]) # rook on b7 pinned to king on b8
  end

  def test_not_pinned_with_piece_between
    # Position where piece would be pinned but another piece blocks the pin
    # d8 = [3,0], d7 = [3,1], d6 = [3,2], d5 = [3,3]
    board = PGN::Board.new([
      [nil, nil, nil, "k", nil, nil, nil, nil],
      [nil, nil, nil, "p", nil, nil, nil, nil],
      [nil, nil, nil, "b", nil, nil, nil, nil],
      [nil, nil, nil, "R", nil, nil, nil, nil],
      [nil, nil, nil, nil, nil, nil, nil, nil],
      [nil, nil, nil, nil, nil, nil, nil, nil],
      [nil, nil, nil, nil, nil, nil, nil, nil],
      [nil, nil, nil, nil, nil, nil, nil, nil]
    ].transpose)

    position = PGN::Position.new(board, :black)
    analyzer = MateAnalyzer.new(position)
    refute analyzer.is_pinned?([3,2], [3,0]) # bishop on d6 not pinned due to pawn on d7
  end

  def test_not_pinned_different_line
    # Position where piece is not on the same line as king and potential pinner
    # d8 = [3,0], c6 = [2,2], d5 = [3,3]
    board = PGN::Board.new([
      [nil, nil, nil, "k", nil, nil, nil, nil],
      [nil, nil, nil, nil, nil, nil, nil, nil],
      [nil, nil, "b", nil, nil, nil, nil, nil],
      [nil, nil, nil, "R", nil, nil, nil, nil],
      [nil, nil, nil, nil, nil, nil, nil, nil],
      [nil, nil, nil, nil, nil, nil, nil, nil],
      [nil, nil, nil, nil, nil, nil, nil, nil],
      [nil, nil, nil, nil, nil, nil, nil, nil]
    ].transpose)

    position = PGN::Position.new(board, :black)
    analyzer = MateAnalyzer.new(position)
    refute analyzer.is_pinned?([2,2], [3,0]) # bishop on c6 not pinned as it's not on same file as king
  end

  def test_many_unpinned
    fen = PGN::FEN.new("6kr/pp2Q1p1/2p5/2bP3p/6b1/8/PPPPNnBP/R1BKR3 w - - 0 20")
    position = fen.to_position
    analyzer = MateAnalyzer.new(position)
    assert_equal "B", position.board.at("c1")
    assert_equal "K", position.board.at("d1")
    assert_equal "K", position.board.at(3, 0)
    assert_equal "R", position.board.at("e1")
    assert_equal "P", position.board.at("c2")
    assert_equal "P", position.board.at("d2")
    assert_equal "N", position.board.at("e2")
    assert_equal "n", position.board.at("f2")
    assert !analyzer.is_pinned?([2, 0], [3, 0])
    assert !analyzer.is_pinned?([2, 1], [3, 0])
    assert !analyzer.is_pinned?([3, 1], [3, 0])
    assert analyzer.is_pinned?([4, 1], [3, 0])
    assert !analyzer.is_pinned?([4, 0], [3, 0])
  end

  def test_find_removable_neighbors
    fen = PGN::FEN.new("6kr/pp2Q1p1/2p5/2bP3p/6b1/8/PPPPNnBP/R1BKR3 w - - 0 20")
    position = fen.to_position
    analyzer = MateAnalyzer.new(position)
    assert_equal "B", position.board.at("c1")
    assert_equal "K", position.board.at("d1")
    assert_equal "K", position.board.at(3, 0)
    assert_equal "R", position.board.at("e1")
    assert_equal "P", position.board.at("c2")
    assert_equal "P", position.board.at("d2")
    assert_equal "N", position.board.at("e2")
    assert_equal "n", position.board.at("f2")
    assert_equal [3, 0], analyzer.find_king_position
    assert_equal [[2, 0], [2, 1], [3, 1], [4, 0]], analyzer.find_removable_neighbors([3, 0]).sort
  end

  def test_find_removable_neighbors_single_rook
    fen = PGN::FEN.new("r3rkR1/1p1b3Q/8/pP1nq1p1/P1p5/4P3/3PN1PP/R5K1 b - - 7 31")
    position = fen.to_position
    analyzer = MateAnalyzer.new(position)
    assert_equal "k", position.board.at(5, 7)
    assert_equal "k", position.board.at("f8")
    assert_equal "r", position.board.at(4, 7)
    assert_equal "r", position.board.at("e8")
    assert_equal "R", position.board.at(6, 7)
    assert_equal "R", position.board.at("g8")
    assert_equal [[4, 7]], analyzer.find_removable_neighbors([5, 7])
  end

  def test_build_analysis
    fen = PGN::FEN.new("r3rkR1/1p1b3Q/8/pP1nq1p1/P1p5/4P3/3PN1PP/R5K1 b - - 7 31")
    position = fen.to_position
    analyzer = MateAnalyzer.new(position)
    assert_equal([6, 7], analyzer.find_checking_pieces([5, 7])[0][:position])
    analysis = analyzer.build_analysis
    assert_equal fen.to_s, analysis[:mate]
    assert_equal "k", position.board.at(5, 7)
    assert_equal "k", position.board.at("f8")
    assert_equal "r", position.board.at(4, 7)
    assert_equal "r", position.board.at("e8")
    assert_equal [], analysis[:analysis][:blocking_squares]
    assert_equal [[4, 7]], analysis[:analysis][:removable_neighbors]
    assert_equal [[6, 7]], analysis[:analysis][:capturable_checkers]
  end

end
