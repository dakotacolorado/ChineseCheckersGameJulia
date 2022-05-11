using Test

# is_point_in_bounds
@test is_point_in_bounds(Int8(-10)) == false
@test is_point_in_bounds(Int8(5)) == true
@test is_point_in_bounds(Int8(10)) == false

# is_position_in_bounds
@test is_position_in_bounds([Int8(-1), Int8(-1)]) == false
@test is_position_in_bounds([Int8( 3), Int8( 0)]) == false
@test is_position_in_bounds([Int8( 1), Int8( 1)]) == true
@test is_position_in_bounds([Int8(10), Int8(10)]) == false

# is_position_open
@test is_position_open([Int8(1), Int8(1)], start_game_state) == false
@test is_position_open([Int8(3), Int8(1)], start_game_state) == false
@test is_position_open([Int8(3), Int8(2)], start_game_state) == false
@test is_position_open([Int8(4), Int8(4)], start_game_state) == true
@test is_position_open([Int8(5), Int8(1)], start_game_state) == true

# is_position_valid
@test is_position_valid([Int8(4),  Int8(4)], start_game_state) == true
@test is_position_valid([Int8(5),  Int8(1)], start_game_state) == true
@test is_position_valid([Int8(10), Int8(1)], start_game_state) == false
@test is_position_valid([Int8(1),  Int8(1)], start_game_state) == false


# get_unit_moves
@test get_unit_moves([Int8(1), Int8(1)], start_game_state) == []
@test get_unit_moves([Int8(4), Int8(1)], start_game_state) == [[1, 0], [0, 1]]
@test get_unit_moves([Int8(9), Int8(9)], start_game_state) == []
@test get_unit_moves([Int8(6), Int8(9)], start_game_state) == [[-1, 0], [0, -1]]

# is_double_move_open
@test is_double_move_open([Int8(1), Int8(1)], unit_moves[1], start_game_state) == false
@test is_double_move_open([Int8(3), Int8(1)], unit_moves[1], start_game_state) == true
@test is_double_move_open([Int8(3), Int8(1)], unit_moves[3], start_game_state) == true
@test is_double_move_open([Int8(9), Int8(9)], unit_moves[2], start_game_state) == false
@test is_double_move_open([Int8(7), Int8(9)], unit_moves[2], start_game_state) == true
@test is_double_move_open([Int8(7), Int8(9)], unit_moves[4], start_game_state) == true
@test is_double_move_open([Int8(1), Int8(2)], unit_moves[6], start_game_state) == false

# get_double_moves
@test get_double_moves([Int8(2), Int8(2)], start_game_state) == [[2, 0], [0, 2]]

p1_t3_positions = map(
    p -> map(Int8, p),
    [ [1, 1], [1, 2], [2, 1], [3, 1], [2, 2], [1, 3], [4, 1], [3, 3], [2, 3], [1, 4] ]
)
t3_game_state = vcat(p1_t3_positions, p2_start_positions)

@test get_double_moves([Int8(1), Int8(2)], p1_t3_positions) == [[2, 2], [2, 0]]

# get player for turn 
@test get_player_for_turn(Int8(1)) == 1
@test get_player_for_turn(Int8(2)) == 2
@test get_player_for_turn(Int8(3)) == 1
@test get_player_for_turn(Int8(4)) == 2

# get positions for player 
@test get_postitions_for_player(Int8(1), start_game_state) == p1_start_positions
@test get_postitions_for_player(Int8(2), start_game_state) == p2_start_positions

# get next moves
@test get_next_moves(start_turn, start_game_state) == [
    [[3, 1], [5, 1]],
    [[3, 1], [3, 3]],
    [[2, 2], [4, 2]],
    [[2, 2], [2, 4]],
    [[1, 3], [3, 3]],
    [[1, 3], [1, 5]],
    [[4, 1], [5, 1]],
    [[4, 1], [4, 2]],
    [[3, 2], [4, 2]],
    [[3, 2], [3, 3]],
    [[2, 3], [3, 3]],
    [[2, 3], [2, 4]],
    [[1, 4], [2, 4]],
    [[1, 4], [1, 5]]
]

# update game state
@test update_game_state([[Int8(3), Int8(1)], [Int8(5), Int8(1)]], start_game_state) == [
    [1, 1],[1, 2],[2, 1],[5, 1],[2, 2],[1, 3],[4, 1],[3, 2],[2, 3],[1, 4],
    [9, 9],[9, 8],[8, 9],[7, 9],[8, 8],[9, 7],[6, 9],[7, 8],[8, 7],[9, 6]
]


# is game won 
@test is_game_won(Int8(1), start_game_state) == false
tie_game_state = vcat(p2_start_positions, p1_start_positions)
@test is_game_won(Int8(1), tie_game_state)== "tie"
p1_win_game_state = vcat(p2_start_positions, p2_start_positions)
@test is_game_won(Int8(1), p1_win_game_state)== "player 1 won"
p2_win_game_state = vcat(p1_start_positions, p1_start_positions)
@test is_game_won(Int8(1), p2_win_game_state)== "player 2 won"


# get_next_game_states(start_turn, start_game_state)