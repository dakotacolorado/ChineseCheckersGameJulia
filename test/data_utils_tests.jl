# encode_game_state
max_state = map(
    p -> map(Int8, [9,9]),
    1:20
)
@test Float64(encode_game_state(max_state)) == Float64(3)^80

min_state = map(
    p -> map(Int8, [1,1]),
    1:20
)
@test Float64(encode_game_state(min_state)) == 0