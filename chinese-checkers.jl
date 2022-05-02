using DataStructures
using LinearAlgebra
using StaticArrays
using JLD
using Distributed
using CUDA

CUDA.allowscalar(false) 

# point : pᵢ ∈ [0,9]
is_point_in_bounds(point :: Int8) = (point ≥ Int8(1)) & (point ≤ Int8(9))

# unit tests : pᵢ
is_point_in_bounds(Int8(-10)) == false
is_point_in_bounds(Int8(5)) == true
is_point_in_bounds(Int8(10)) == false

# position : p ∈ [0,9]²
function is_position_in_bounds(position :: SVector{2, Int8}) 
    return is_point_in_bounds(position[1]) & is_point_in_bounds(position[2])
end

# unit tests : p
is_position_in_bounds(SVector(Int8(-1), Int8(-1))) == false
is_position_in_bounds(SVector(Int8( 3), Int8( 0))) == false
is_position_in_bounds(SVector(Int8( 1), Int8( 1))) == true
is_position_in_bounds(SVector(Int8(10), Int8(10))) == false

# diagonal projection : p₁ + p₂
diagonal_projection(position :: SVector{2, Int8}) = position[1] + position[2] 

# unit tests : diagonal_projection(p)
diagonal_projection(SVector(Int8( 0), Int8( 0)))  ==  0
diagonal_projection(SVector(Int8( 2), Int8( 2)))  ==  4
diagonal_projection(SVector(Int8(-2), Int8(-2)))  == -4

# perpendicular projection : Φ(p) = p₁ - p₂
perpendicular_projection(position :: SVector{2, Int8}) = position[1] - position[2] 

# unit tests : perpendicular_projection(p)
perpendicular_projection(SVector(Int8(0),Int8(0))) ==  0
perpendicular_projection(SVector(Int8(2),Int8(2))) ==  0
perpendicular_projection(SVector(Int8(2),Int8(3))) == -1
perpendicular_projection(SVector(Int8(3),Int8(2))) ==  1

# unit moves : Ω = {(m₁, m₂) | mᵢ ∈ {-1, 0, 1}, m₁ + m₂ ≤ 2}
Ω = SVector{6}(map(
    m -> SVector{2}(Int8(m[1]), Int8(m[2])),
    [ 
        [1 0], [-1 0], [0 1], [0 -1], [-1 1], [1 -1]
    ]
))

# unit test : Ω 
filter(ω -> (ω[1] + ω[2] < 5) & (ω[1] + ω[2] > 1), Ω) == []

# start positions : P₀ = {(p₁, p₂) | pᵢ ∈ [1, 9], p₁ + p₂ ≤ 5}
P₀ =  SVector{10}(map(
    p -> SVector{2}(Int8(p[1]), Int8(p[2])),
    [ 
        [1 1], [1 2], [2 1], [3 1], [2 2],
        [1 3], [4 1], [3 2], [2 3], [1 4]
    ]
))

# unit tests : P₀
filter(is_position_in_bounds, P₀) == P₀ 
filter(p -> p[1] + p[2] > 5, P₀) == []

# target positions : P₁ = {(p₁, p₂) | pᵢ ∈ [1, 9], p₁ + p₂ ≥ 13}
P₁ = map(p -> SVector{2}(Int8(10 - p[1]), Int8(10 - p[2])), P₀)

# unit tests : P₁
filter(is_position_in_bounds, P₁) == P₁ 
filter(p ->  p[1] + p[2] < 12, P₁) == []

# is position open : p ∉ P₀ ∪ P₁
function is_position_open(
    position :: SVector{2, Int8}, 
    Positions :: SVector{20, SVector{2, Int8}}
    ) 
    return  ~ mapreduce(q -> q == position, |, Positions)
end

# unit tests : is_position_open
P = vcat(P₀, P₁)
is_position_open(SVector(Int8(1), Int8(1)), P) == false
is_position_open(SVector(Int8(3), Int8(1)), P) == false
is_position_open(SVector(Int8(3), Int8(2)), P) == false
is_position_open(SVector(Int8(4), Int8(4)), P) == true
is_position_open(SVector(Int8(5), Int8(1)), P) == true


# move : m ∈ [0,9]² 
# direction : d ∈ {-1, 1}
# is move forward : (v₁ + v₂) ⋅ d ≥ 0
function is_move_forward(
    move :: SVector{2, Int8}, 
    direction :: Int8
    ) 
    return diagonal_projection(move) ⋅ direction ≥ 0
end

# unit tests
is_move_forward(SVector(Int8( 1), Int8( 1)), Int8(1) ) == true
is_move_forward(SVector(Int8(-1), Int8( 1)), Int8(1))  == true
is_move_forward(SVector(Int8(-1), Int8(-1)), Int8(1))  == false
is_move_forward(SVector(Int8(-1), Int8(-1)), Int8(-1)) == true
is_move_forward(SVector(Int8(-1), Int8( 1)), Int8(-1))  == true
is_move_forward(SVector(Int8(-1), Int8(-1)), Int8(1)) == false
is_move_forward(SVector(Int8(0 ), Int8( 0)), Int8(1))   == true

# start unit moves : Ω₀ = {ω | ω ∈  Ω, is_move_forward(ω, 1)}
Ω₀ = filter(m -> is_move_forward(m, Int8(1)), Ω)

# target unit moves : Ω₁ = {ω | ω ∈  Ω, is_move_forward(ω, -1)}
Ω₁ = filter(m -> is_move_forward(m, Int8(-1)), Ω)

# position : p ∈ [0,9]² 
# is position valid : (p ∈ [0,9]²) & (p ∉ P₀ ∪ P₁) 
function is_position_valid(
    position ::SVector{2, Int8}, 
    Positions :: SVector{20, SVector{2, Int8}}
    ) 
    is_valid =  is_position_in_bounds(position)
    is_valid &= is_position_open(position, Positions)
    return is_valid
end

# position : p ∈ [0,9]² 
# direction : d ∈ {-1, 1}
function get_unit_moves(
    position :: SVector{2, Int8}, 
    direction :: Int8, 
    Positions :: SVector{20, SVector{2, Int8}}
    ) 
    return filter(
        move -> is_position_valid(position + move, Positions), 
        direction == 1 ? Ω₀ : Ω₁
    )
end

# unit test
function remove_empty_positions(
    Positions :: SVector{4, SVector{2, Int8}}
    ) 
    return filter(
        position -> position != SVector{2}(Int8(0), Int8(0)), 
        Positions
    )
end

get_unit_moves(SVector(Int8(1), Int8(1)), Int8(1), P)== []
get_unit_moves(SVector(Int8(2), Int8(2)), Int8(1), P) == []
get_unit_moves(SVector(Int8(3), Int8(2)), Int8(1), P) ==  [SVector(1, 0), SVector(0, 1)]

# position : p ∈ [0,9]² 
# move : m ∈ [0,9]²  
function is_double_move_open(
    position :: SVector{2, Int8}, 
    move :: SVector{2, Int8}, 
    Positions :: SVector{20, SVector{2, Int8}}
    ) 
    is_open = ~is_position_open(position + move, Positions)
    is_open &= is_position_valid(map(Int8, position + 2*move), Positions)
    return is_open
end

# unit tests
is_double_move_open(SVector(Int8(1), Int8(1)), SVector(Int8(1), Int8(0)), P) == false
is_double_move_open(SVector(Int8(3), Int8(1)), SVector(Int8(1), Int8(0)), P) == true

# position : p ∈ [0,9]² 
# direction : d ∈ {-1, 1}
function get_double_moves(
    position :: SVector{2, Int8}, 
    direction :: Int8, 
    Positions :: SVector{20, SVector{2, Int8}}
    ) 
    visited_moves = Set{SVector{2, Int8}}()
    moves_queue   = Array{SVector{2, Int8}}([SVector(Int8(0), Int8(0))])
    while length(moves_queue) > 0
        moves = map( 
            move -> map( 
                n -> map(Int8,2*n), 
                filter( 
                    ω -> is_double_move_open(
                        position + move, 
                        ω,
                        Positions
                    ), 
                    Ω
                ) 
            ), 
            moves_queue
        )
        moves = filter(
            move -> is_move_forward(move, direction), 
            collect(
                Iterators.flatten(
                    moves
                )
            )
        )
        moves_queue = setdiff(moves, visited_moves)
        visited_moves = union(visited_moves, moves)
    end
    
    return collect(visited_moves)
end


# unit tests
Array(get_double_moves(SVector(Int8(3), Int8(1)), Int8(1), P)) == [SVector(2, 0), SVector(0, 2)]
Array(get_double_moves(SVector(Int8(1), Int8(3)), Int8(1), P)) == [SVector(2, 0), SVector(0, 2)]

# positions : P ∈ [0,9]²ˣ¹⁰
# index : i ∈ Ζ
# position : p ∈ [0,9]² 
function replace_position(
    Positions :: SVector{10, SVector{2, Int8}}, 
    index :: Int8, 
    new_position :: SVector{2, Int8}
    )
    return SVector{10}(map(
        ((j, position), ) -> j == index ? new_position : position, 
        enumerate(Positions)
    ))
end

# unit test
replace_position(P₀, Int8(4), SVector(Int8(2), Int8(4))) == SVector{10}(map(
    p -> SVector{2}(Int8(p[1]), Int8(p[2])), 
    [
        [1 1], [1 2], [2 1], [2 4], [2 2], 
        [1 3], [4 1], [3 2], [2 3], [1 4]
    ]
))


# active positions : R ∈ [0,9]²ˣ¹⁰
# direction : d ∈ {-1, 1}
function get_next_positions(
    active_Positions :: SVector{10, SVector{2, Int8}}, 
    direction :: Int8,
    Positions :: SVector{20, SVector{2, Int8}}
    )
    return collect(
        Iterators.flatten(
            map(
                ((i, position), ) -> map(
                    move -> replace_position(active_Positions, Int8(i), position + move), 
                    vcat(
                        get_unit_moves(position, direction, Positions), 
                        get_double_moves(position, direction, Positions))
                    ), 
                enumerate(active_Positions)
            )
        )
    )
end

# unit tests 
length(get_next_positions(P₀, Int8(1), P))  == 14
length(get_next_positions(P₁, Int8(-1), P)) == 14

# active positions : R₀ ∈ [0,9]²ˣ¹⁰
# other positions : R₁ ∈ [0,9]²ˣ¹⁰
# direction : d ∈ {-1, 1}
function get_position_transitions(
    active_Positions :: SVector{10, SVector{2, Int8}}, 
    other_Positions :: SVector{10, SVector{2, Int8}}, 
    direction :: Int8
    )
    next_positions = get_next_positions(
        active_Positions, 
        direction, 
        vcat(
            active_Positions, 
            other_Positions
        )
    )
    return SVector(
        active_Positions, 
        other_Positions, 
        next_positions
    )
end

# unit tests
get_position_transitions(P₀, P₁, Int8(1))[1] == P₀
get_position_transitions(P₀, P₁, Int8(1))[2] == P₁
length(get_position_transitions(P₀, P₁, Int8(1))[3]) == 14
length(get_position_transitions(P₁, P₀, Int8(-1))[3]) == 14


function get_priority_states(
    states :: CuArray{SVector{2, SVector{10}}},
    direction :: Int8
    )

    active_states = Set()
    for transition in states
        push!(target_states, transition[2])
    end

    # define priority order  
    states_queue = PriorityQueue()
    for state in target_states
        enqueue!(states_queue, state, 0)
    end
    
    states_count = length(states_queue)
    priority_states = []
    for i in 1:min(states_count, state_limit)
        push!(priority_states, dequeue!(states_queue))
    end

    return priority_states
end

# unit tests


active_player_for_turn(turn) = Int8((turn % 2)*2 - 1)

# unit tests
active_player_for_turn(2) isa Int8
active_player_for_turn(1) == 1
active_player_for_turn(2) == -1

root_directory = "A:/Projects/chinese-checkers/"
filename = "states.jld"

# state_transitions = load(turn_directory * filename)["transitions"]
start_turn = 4
end_turn   = 7
turn_directory = root_directory * "turn=" * string(start_turn) * "/"
if start_turn == 1
    transitions = [get_position_transitions(P₀, P₁, Int8(1))]
    mkpath(turn_directory)
    save(turn_directory * filename, "transitions", transitions)
else
    transitions = load(turn_directory * filename)["transitions"]
end

for turn in start_turn:end_turn-1
    next_states = []
    for transition in transitions
        next_states = vcat(
            next_states,
            map(
                position -> [
                    transition[2], 
                    position
                ],
                transition[3]
            )
        )
    end

    print(length(next_states))
    print("\n")

    transitions = map(
        state -> get_position_transitions(
            state[1],
            state[2],
            active_player_for_turn(turn+1)
        ),
        next_states
    )

    turn_directory = root_directory * "turn=" * string(turn+1) * "/"
    mkpath(turn_directory)
    save(turn_directory * filename, "transitions", transitions)
end





get_next_positions(P₀)
get_position_transitions(P₀, P₁, Int8(1))












S₀ = SVector(Q₀ ,Q₁)
position_transitions = get_position_transitions(S₀[1], S₀[2], Int8(1))
next_positions = CuArray(position_transitions[3])





turn_transitions = vcat()
for i in 2:3
    print(len(next_positions))
    print("\n")
    turn_transitions = position_transitions
    
    position_transitions =  get_position_transitions
    

    position_transitions = get_position_transitions(S₀[1], S₀[2], Int8(1))




function first_order_binary_functions(
    x :: Int8, 
    y :: Int8, 
    a₀₀ :: Float16,
    a₀₁ :: Float16,
    a₁₀ :: Float16,
    a₁₁ :: Float16
    )
    return a₀₀ + a₀₁*x + a₁₀*y + a₁₁*x*y
end



# unordered arguements can only be mapped with symetric functions
# f(x, y) = f(y, x)
# f(x, y, z) = f(x, z, y) = f(y, x, z) = f(y, z, x) = f(z, x, y) = f(z, y, x)
function first_order_symetric_functions(
    x₁ :: Int8,
    x₂ :: Int8,
    x₃ :: Int8,
    x₄ :: Int8,
    x₅ :: Int8,
    x₆ :: Int8,
    x₇ :: Int8,
    x₈ :: Int8,
    x₉ :: Int8,
    x₁₀ :: Int8,
    )

end



struct turn_transition
    P₀ :: Array
    P₁ :: Array
    P₂ :: Array
end

# all active positions for turn and other positions: T ∈ [0,9]²ˣ¹⁰ˣᴺ
# other positions : R ∈ [0,9]²ˣ¹⁰
# direction : d ∈ {-1, 1}
function get_turn_transitions(T :: Vector{turn_transition})
    next_positions = collect(
        Iterators.flatten(
            map( t ->
                map(
                    S -> [
                        t.P₁,
                        S
                    ],
                    t.P₂
                ),
                T
            )
        )
    )
    return next_positions
end

T₀ = [
    turn_transition(
        [],
        Q₀,
        [Q₁]
    )
]
get_turn_transitions(T₀)[1]

# make this run on GPU
function get_state_transitions(states :: Vector, active_player :: Int8)
    state_transitions = Set()
    for state in states
        positions = get_player_positions(state, active_player)
        for (index, position) in enumerate(positions)
            moves = vcat(
                get_unit_moves(position, active_player), 
                get_diagonal_moves(position, active_player)
            ) 
            for move in moves
                state_transition = replace_position(state, index, position + move)
                push!(state_transitions, [state, state_transition])
            end
        end
    end
    return collect(state_transitions)
end

# unit test
length(get_state_transitions([start_state], Int8(1))) == 14

# make this run on GPU
state_limit = 1000000
function get_priority_transitions(state_transitions :: Array, active_player :: Bool)

    target_states = Set()
    for transition in state_transitions
        push!(target_states, transition[2])
    end

    # define priority order  
    states_queue = PriorityQueue()
    for state in target_states
        enqueue!(states_queue, state, 0)
    end
    
    states_count = length(states_queue)
    priority_states = []
    for i in 1:min(states_count, state_limit)
        push!(priority_states, dequeue!(states_queue))
    end

    return priority_states
end


# unit tests
active_player_for_turn(1) == 1
active_player_for_turn(2) == 2
active_player_for_turn(3) == 1

swap_player(active_player) = (active_player) % 2 + 1  

# unit tests
swap_player(1) == 2
swap_player(2) == 1

# main 
function main(start_turn :: Int8 = 1, end_turn :: Int8 = 3)
    root_directory = "A:/Projects/chinese-checkers/"
    filename = "states.jld"

    if start_turn == 1
        previous_states = [start_state]
    else
        turn_directory = root_directory * "turn=" * string(start_turn-1) * "/"
        state_transitions = load(turn_directory * filename)["state_transitions"]
        previous_states = get_priority_transitions(
            state_transitions,
            active_player_for_turn(start_turn)
        )
    end

    for turn in start_turn:end_turn
        active_player = active_player_for_turn(turn)

        state_transitions = get_state_transitions(
            previous_states, 
            active_player
        )

        turn_directory = root_directory * "turn=" * string(turn-1) * "/"
        print(turn_directory)
        print("\n")
        print(length(state_transitions))
        print("\n")
        
        mkpath(turn_directory)
        save(turn_directory * filename, "state_transitions", state_transitions)

        previous_states = get_priority_transitions(
            state_transitions,
            active_player
        )

        active_player = swap_player(active_player)
    end
end







