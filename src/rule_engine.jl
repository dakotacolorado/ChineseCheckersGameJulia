# p1 start positions : P₁₀ = {(p₁, p₂) | pᵢ ∈ [1, 9], p₁ + p₂ ≤ 5}
p1_start_positions = map(
    p -> map(Int8, p),
    [ 
        [1, 1], [1, 2], [2, 1], [3, 1], [2, 2],
        [1, 3], [4, 1], [3, 2], [2, 3], [1, 4]
    ]
)

# p2 start positions : P₂₀ = {(p₁, p₂) | pᵢ ∈ [1, 9], p₁ + p₂ ≥ 13}
p2_start_positions = map(
    p -> map(q -> Int8(10 - q), p), 
    p1_start_positions
)

p1_target_positions = copy(p2_start_positions)
p2_target_positions = copy(p1_start_positions)

# game state : Sₜ = P₁ₜ ∪ P₂ₜ
start_game_state = vcat(p1_start_positions, p2_start_positions)

# unit moves : Ω = {(m₁, m₂) | mᵢ ∈ {-1, 0, 1}, m₁ + m₂ ≤ 2}
unit_moves = map(
    m -> map(Int8, m),
    [ [1,0], [-1, 0], [0, 1], [0, -1], [-1, 1], [1, -1] ]
)

# start turn : t ∈ ℤ 
start_turn = Int8(1)

# is point in bounds : pᵢ ∈ [1,9]
function is_point_in_bounds(
    point :: Int8
    ) 
    return (point ≥ Int8(1)) & (point ≤ Int8(9))
end

# is position in bounds : p ∈ [1,9]²
function is_position_in_bounds(
    position :: Vector{Int8}
    ) 
    return is_point_in_bounds(position[1]) & is_point_in_bounds(position[2])
end

# is position open : p ∉ Sₜ
function is_position_open(
    position :: Vector{Int8}, 
    game_state :: Vector{Vector{Int8}}
    ) 
    return  ~ mapreduce(p -> p == position, |, game_state)
end

# is position valid : (p ∈ [0,9]²) & (p ∉ Sₜ) 
function is_position_valid(
    position ::Vector{Int8}, 
    game_state :: Vector{Vector{Int8}}
    ) 
    is_valid =  is_position_in_bounds(position)
    is_valid &= is_position_open(position, game_state)
    return is_valid
end

# get unit moves : {ω | ω ∈ Ω, p + ω ∉ P, p + ω ∈ [0,9]²}
function get_unit_moves(
    position :: Vector{Int8}, 
    game_state :: Vector{Vector{Int8}}
    ) 
    return filter(
        move -> is_position_valid(position + move, game_state), 
        unit_moves
    )
end

# is double move open : (p + m ∈ P) & (p + 2*m ∉ P) & (p + 2*m ∈ [0,9]²)
function is_double_move_open(
    position :: Vector{Int8}, 
    move :: Vector{Int8}, 
    game_state :: Vector{Vector{Int8}}
    ) 
    is_open = ~is_position_open(position + move, game_state)
    is_open &= is_position_valid(map(Int8, position + 2*move), game_state)
    return is_open
end

# get double moves : 
function get_double_moves(
    position :: Vector{Int8}, 
    Positions :: Vector{Vector{Int8}}
    ) 
    visited_moves = Set{Vector{Int8}}()
    moves_queue   = Vector{Vector{Int8}}([[Int8(0), Int8(0)]])
   
    while length(moves_queue) > 0
        next_moves = map( 
            move -> map( 
                n -> map(Int8, 2*n) + move, 
                filter( 
                    ω -> is_double_move_open(
                        position + move, 
                        ω,
                        Positions
                    ), 
                    unit_moves
                ) 
            ), 
            moves_queue
        )
        next_moves = collect(Iterators.flatten(next_moves))
        moves_queue = setdiff(next_moves, visited_moves)
        visited_moves = union(visited_moves, next_moves)
    end
    return collect(visited_moves)
end

# get player for turn : (1 + t) % 2 + 1
function get_player_for_turn(
    turn :: Int8
    )
    return Int8((1 + turn) % 2 + 1)
end

# get positions for player : 
function get_postitions_for_player(
    player :: Int8,
    game_state :: Vector{Vector{Int8}}
    )
    return player == 1 ? game_state[1:10] : game_state[11:20]
end

# get next moves : 
function get_next_moves(
    turn :: Int8,
    game_state :: Vector{Vector{Int8}}
    )
    player = get_player_for_turn(turn)
    positions = get_postitions_for_player(player, game_state)
    next_moves = map(
        position -> map(
            move -> [position, position + move], 
            vcat(
                get_unit_moves(position, game_state), 
                get_double_moves(position, game_state)
            )
        ), 
        positions
    )
    next_moves = collect(Iterators.flatten(next_moves))
    return next_moves
end

# update game state : 
function update_game_state(
    move :: Vector{Vector{Int8}},
    game_state :: Vector{Vector{Int8}}
    )
    return map(
        position -> position == move[1] ? move[2] : position,
        game_state
    )
end

# get next game states : 
function get_next_game_states(
    turn :: Int8,
    game_state :: Vector{Vector{Int8}}
    )
    next_moves = get_next_moves(turn, game_state)
    return map(
        move -> update_game_state(move, game_state),
        next_moves
    )
end

# is game won 
function is_game_won(
    turn :: Int8,
    game_state :: Vector{Vector{Int8}}
    )
    player = get_player_for_turn(turn)
    
    p1_positions = get_postitions_for_player(Int8(1), game_state)
    p2_positions = get_postitions_for_player(Int8(2), game_state)
    
    if player == 1
        if p1_positions == p1_target_positions
            if p2_positions == p2_target_positions
                return "tie"
            else
                return "player 1 won"
            end
        elseif p2_positions == p2_target_positions
            return "player 2 won"
        else
            return false
        end
    else
        return false
    end
end