using ChineseCheckers
using StaticArrays
using JLD2
using FileIO

# Approximate a function 
# 𝑓 : [0,9]¹⁰ˣ²ˣ² ↦ [0,10⁴⁰]
# ([x,y] denotes the set of integers from x to y inclusive)



# perpendicular projection : p₁ - p₂
function perpendicular_distance(
    position :: Vector{Int8}
    ) 
    return abs(position[1] - position[2])
end 

# Start Scores
#   player 1:  120 (min)
#   player 2: -120 (max)
function get_naive_score(
    game_state :: Vector{Vector{Int8}}
    )
    player_1 = get_postitions_for_player(Int8(1), game_state)
    player_2 = get_postitions_for_player(Int8(2), game_state)

    # worst case distance 
    player_1_score = 160 - sum(reduce(vcat, player_1)) # start = 40
    player_2_score = 40  - sum(reduce(vcat, player_2)) # start = 160

    # penalize spread (max spread = 68)
    player_1_score += mapreduce(perpendicular_distance, +, player_1)/69
    player_2_score -= mapreduce(perpendicular_distance, +, player_2)/69

    score = player_1_score + player_2_score
     
    return Float16(score == 0 ? (0.5-rand())/35 : score)
end


function get_feature_scores(
    game_state_features :: Dict{UInt128, Vector}
    )
    game_state_scores = Dict{UInt128, Float16}()
    for (key, value) in game_state_features
        game_state_scores[key] = Float16(value[1])/Float16(value[2])
    end
    return game_state_scores
end

score_bounds = [-120,120]
function get_next_best_game_state(
    turn :: Int16,
    game_state :: Vector{Vector{Int8}},
    game_state_scores :: Dict{UInt128, Float16},
    )
    player = get_player_for_turn(turn)
    next_game_states = get_next_game_states(turn, game_state)

    best_game_state = Vector{Vector{Int8}}()
    best_game_score = score_bounds[player]
    for state in next_game_states
        score = get(
            game_state_scores,
            encode_game_state(state), 
            get_naive_score(state)
        )
        if player == 1
            if score < best_game_score
                best_game_state = state
                best_game_score = score
            end
        else
            if score > best_game_score
                best_game_state = state
                best_game_score = score
            end
        end
    end
    return best_game_state
end

