using ChineseCheckers
using StaticArrays
using JLD2
using FileIO

# Approximate a function 
# 𝑓 : [0,9]¹⁰ˣ²ˣ² ↦ [0,10⁴⁰]
# ([x,y] denotes the set of integers from x to y inclusive)

longest_game = 160

# diagonal projection : p₁ + p₂
function diagonal_projection(
    position :: Vector{Int8}
    ) 
    return position[1] + position[2]
end

# perpendicular projection : p₁ - p₂
function perpendicular_projection(
    position :: Vector{Int8}
    ) 
    return position[1] - position[2]
end 

# move : m ∈ [0,9]² 
# direction : d ∈ {-1, 1}
# is move forward : (v₁ + v₂) ⋅ d ≥ 0
function is_move_forward(
    move :: SVector{2, Int8}, 
    direction :: Int8
    ) 
    return diagonal_projection(move) * direction ≥ 0
end

function get_naive_score(
    turn :: Int8,
    game_state :: Vector{Vector{Int8}}
    )
    player = get_player_for_turn(turn)
    positions = get_postitions_for_player(player, game_state)
    if player == 1
        score = 160 - sum(reduce(vcat, positions)) 
        score += abs(mapreduce(perpendicular_projection, +, positions)/100)
    else 
        score = 40 - sum(reduce(vcat, positions)) 
        score -= abs(mapreduce(perpendicular_projection, +, positions)/100)
    end
    return score
end

get_naive_score(Int8(1),start_game_state) == 120
get_naive_score(Int8(2),start_game_state) == -120


function encode_game_state(
    game_state :: Vector{Vector{Int8}}
    )
    flat_state = reduce(vcat,game_state)
    encoding = UInt128(0)
    for (i,v) in enumerate(flat_state)
        encoding += 2^(i*9-v)
    end 
    return encoding
end

encode_game_state(start_game_state) == 0x00000000000000001010100802020100

function read_game_state_data(
    filename :: String
    )
    return load(filename)["data"]
end

function write_game_state_data(
    filename :: String,
    game_state_data :: Dict{UInt128, Vector{Int8}}
    )
    save(filename, "data", game_state_data)
end

function get_state_scores(
    game_state_data :: Dict{UInt128, Vector{Int8}}
    )
    game_state_scores = Dict{Unit128, Float64}()
    for (key, value) in game_state_data
        game_state_scores[key] = value[0]/value[1]
    end
end


function get_next_best_game_state(
    turn :: Int8,
    game_state :: Vector{Vector{Int8}},
    game_state_scores :: Dict{UInt128, Int8}
    )
    player = get_player_for_turn(turn)
    next_game_states = get_next_game_states(turn, game_state)

    best_game_state = Vector{Vector{Int8}}()
    best_game_score = player == 1 ? longest_game : -longest_game
    best_random_score = rand()
    for (i, state) in enumerate(next_game_states)
        score = get(
            game_state_scores,
            encode_game_state(state), 
            get_naive_score(turn, state)
        )
        if player == 1
            if score < best_game_score
                best_game_state = state
                best_game_score = score
            elseif score == best_game_score
                random_score = rand()
                if random_score > best_random_score
                    print(best_random_score , "\n")
                    best_game_state = state
                    best_game_score = score
                    best_random_score = random_score
                end
            end
        else
            if score > best_game_score
                best_game_state = state
                best_game_score = score
            elseif score == best_game_score
                random_score = rand()
                if random_score > best_random_score
                    best_game_state = state
                    best_game_score = score
                    best_random_score = random_score
                end
            end
        end
    end
    return best_game_state
end

