# state_data_filename = "model-a.jld"
# game_state_data = read_game_state_data(state_data_filename)
# Start Scores
#   player 1:  120 (min)
#   player 2: -120 (max)

# function play_game(
#     player_1_game_state_features :: Dict{UInt128, Vector},
#     player_2_game_state_features :: Dict{UInt128, Vector},
#     feature_scoring_function
#     )
#     player_1_scores = feature_scoring_function(player_1_game_state_features)
#     player_2_scores = feature_scoring_function(player_2_game_state_features)



#     while win_status != "tie" && turn < 180

#         # next state
#         game_state = get_next_best_game_state(
#             turn,
#             game_state,
#             player == 1 ? player_1_scores : player_2_scores
#         )
#         turn = Int16(turn + 1)
#         player = get_player_for_turn(turn)
        
#         if player == 1
#             win_status = is_game_won(turn, game_state)
#         end

#         if win_status == "player 1 won"
#             player_1_win_turn = player_1_win_turn == false ? ceil(turn/2) : player_1_win_turn
#             turn = player == 1 ? Int16(turn + 1) : turn
#         elseif win_status == "player 2 won"
#             player_2_win_turn = player_2_win_turn == false ? ceil(turn/2) : player_2_win_turn
#             if player == 2
#                 turn = Int16(turn + 1)
#                 win_status = is_game_won(turn, game_state)
#             end 
#         end
        
#         # print(player, " ", turn, " ", Int16(ceil(turn/2)), " ",win_status, "\n")
#         if show_game
#             display(print_game_state(game_state))
#             sleep(0.01)
#         end
#         # sleep(0.001)

#         push!(
#             player == 1 ? player_1_history : player_2_history, 
#             encode_game_state(game_state)
#         )

#     end
#     player_1_win_turn = player_1_win_turn == false ? ceil(turn/2) : player_1_win_turn
#     player_2_win_turn = player_2_win_turn == false ? ceil(turn/2) : player_2_win_turn

#     win_turn_difference = player_2_win_turn - player_1_win_turn

#     for s in player_1_history
#         if s in keys(player_1_game_state_data)
#             player_1_game_state_data[s] = [
#                 player_1_game_state_data[s][1] + win_turn_difference,
#                 player_1_game_state_data[s][2] + 1
#             ]
#         else player_1_game_state_data[s] = [
#             win_turn_difference,
#             1
#         ]
#         end
#     end
    
#     for s in player_2_history
#         if s in keys(player_2_game_state_data)
#             player_2_game_state_data[s] = [
#                 player_2_game_state_data[s][1] + win_turn_difference,
#                 player_2_game_state_data[s][2] + 1
#             ]
#         else player_2_game_state_data[s] = [
#             win_turn_difference,
#             1
#         ]
#         end
#     end

#     return (
#         min(player_1_win_turn, player_2_win_turn),
#         player_1_game_state_data,
#         player_2_game_state_data
#     )
# end

# player_1_game_state_data = Dict{UInt128, Vector}()
# player_2_game_state_data = Dict{UInt128, Vector}()
# win_distance_history = []
# average = (v) -> Int(ceil(sum(v)/length(v)))

# for i in 1:999
#     (   
#         win_distance,
#         player_1_game_state_data,
#         player_2_game_state_data
#     ) = play_game(
#         player_1_game_state_data,
#         player_2_game_state_data
#     )
#     push!(win_distance_history,win_distance)
#     print(i, ", ", win_distance, ", ", average(win_distance_history), "\n")
# end

# player_1_game_state_data
# print(get_state_scores(player_2_game_state_data))



# function play_chinese_checkers(
#     player_1_model,
#     player_2_model,
#     train_players = false,
#     show_game = false,
#     max_turns = 200
#     )
#     player_1_model = load_model(player_1_filename)
#     player_2_model = load_model(player_2_filename)


#     # initial state
#     game_state = start_game_state
#     turn = Int16(1)
#     player = get_player_for_turn(turn)

#     player_1_win_turn = false
#     player_2_win_turn = false

#     win_status = is_game_won(turn, game_state)

#     player_1_history = Dict{UInt64, Int16}()
#     player_2_history = Dict{UInt64, Int16}()


#     while win_status != "tie" && turn < max_turns

#         # next state
#         game_state = player == 1 ? player_1_model(game_state) : player_2_model(game_state)

#         encoded_state = encode_game_state(game_state)
#         if player == 1
#             if !(encoded_state in keys(player_1_history))
#                 player_1_history[encoded_state] = turn
#             end
#         else 
#             if !(encoded_state in keys(player_2_history))
#                 player_2_history[encoded_state] = turn
#             end        
#         end
        
#         turn = Int16(turn + 1)
#         player = get_player_for_turn(turn)
        
#         # check if a player has won the game
#         if player == 1
#             win_status = is_game_won(turn, game_state)
#         end

#         # wait for the other player finish 
#         if win_status == "player 1 won"
#             player_1_win_turn = player_1_win_turn == false ? turn : player_1_win_turn
#             turn = player == 1 ? Int16(turn + 1) : turn
#         elseif win_status == "player 2 won"
#             player_2_win_turn = player_2_win_turn == false ? turn : player_2_win_turn
#             if player == 2
#                 turn = Int16(turn + 1)
#                 win_status = is_game_won(turn, game_state)
#             end 
#         end

#         if show_game
#             display(print_game_state(game_state))
#             sleep(0.01)
#         end

#     end
#     player_1_win_turn = player_1_win_turn == false ? turn : player_1_win_turn
#     player_2_win_turn = player_2_win_turn == false ? turn : player_2_win_turn

#     win_distance = player_2_win_turn - player_1_win_turn

#     if train_players
#         player_1_model = player_1_model, player_1_history,win_distance)
#         player_2_model = player_2_filename,player_2_model, player_2_history,win_distance)
#     end

#     return (
#         win_distance,
#         min(player_1_win_turn, player_2_win_turn)
#     )
# end
