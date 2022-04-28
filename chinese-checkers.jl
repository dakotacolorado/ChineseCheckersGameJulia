using DataStructures
using LinearAlgebra
using JLD
using Distributed
using CUDA

CUDA.allowscalar(false)

# gpu tests
@time dot(CUDA.rand(Int8,999999999), CUDA.rand(Int8,999999999))
@time dot(rand(Int8,2999999999), rand(Int8,2999999999))
CUDA.memory_status()  
CUDA.reclaim()    


# point : pᵢ ∈ [0,9]
is_point_in_bounds(pᵢ :: Int8) = (pᵢ ≥ Int8(1)) & (pᵢ ≤ Int8(9))

# unit tests : pᵢ
is_point_in_bounds(Int8(-10)) == false
is_point_in_bounds(Int8(5)) == true
is_point_in_bounds(Int8(10)) == false

struct Position 
    p₁ :: Int8
    p₂ :: Int8
end

# position : p ∈ [0,9]²
is_position_in_bounds(p :: Position) = is_point_in_bounds(p.p₁) & is_point_in_bounds(p.p₂)

# unit tests : p
is_position_in_bounds(Position(-1, -1)) == false
is_position_in_bounds(Position(3, 0)) == false
is_position_in_bounds(Position(1, 1)) == true
is_position_in_bounds(Position(10, 10)) == false

# diagonal projection : p₁ + p₂
diagonal_projection(p :: Position) = p.p₁ + p.p₂ 

# unit tests : diagonal_projection(p)
diagonal_projection(Position(0, 0))  ==  0
diagonal_projection(Position(2, 2))  ==  4
diagonal_projection(Position(-2,-2)) == -4

# perpendicular projection : Φ(p) = p₁ - p₂
perpendicular_projection(p :: Position) = p.p₁ - p.p₂ 

# unit tests : perpendicular_projection(p)
perpendicular_projection(Position(0,0)) ==  0
perpendicular_projection(Position(2,2)) ==  0
perpendicular_projection(Position(2,3)) == -1
perpendicular_projection(Position(3,2)) ==  1

struct Move 
    m₁ :: Int8
    m₂ :: Int8
end

# unit moves : Ω = {(m₁, m₂) | mᵢ ∈ {-1, 0, 1}, m₁ + m₂ ≤ 2}
Ω = map(m -> Move(m[1], m[2]),[ 
    [1 0], [-1 0], [0 1], [0 -1], [-1 1], [1 -1]
])

# unit test : Ω 
filter(ω -> (ω.m₁ + ω.m₂ < 5) & (ω.m₁ + ω.m₂ > 1), Ω) == []

# start positions : P₀ = {(p₁, p₂) | pᵢ ∈ [1, 9], p₁ + p₂ ≤ 5}
P₀ = CuArray(map(p -> Position(p[1], p[2]),[ 
    [1 1], [1 2], [2 1], [3 1], [2 2],
    [1 3], [4 1], [3 2], [2 3], [1 4]
]))

# active positions : Q₀
Q₀ = copy(P₀)

# unit tests : P₀
filter(is_position_in_bounds, P₀) == P₀ 
filter(p -> p.p₁ + p.p₂ > 5, P₀) == []

# target positions : P₁ = {(p₁, p₂) | pᵢ ∈ [1, 9], p₁ + p₂ ≥ 13}
P₁ = map(p -> Position(10 - p.p₁, 10 - p.p₂), P₀)

# other positions : Q₁
Q₁ = copy(P₁)

# unit tests : P₁
filter(is_position_in_bounds, P₁) == P₁ 
filter(p ->  p.p₁ + p.p₂ < 12, P₁) == []

vcat(Q₀, Q₁)

# is position open : p ∉ P₀ ∪ P₁
is_position_open(p :: Position) = ~ mapreduce(q -> q == p, |, vcat(Q₀, Q₁))
Position(1,1) == Position(1,1)
# unit tests : is_position_open
is_position_open(Position(1, 1)) == false
is_position_open(Position(3, 1)) == false
is_position_open(Position(3, 2)) == false
is_position_open(Position(4, 4)) == true
is_position_open(Position(5, 1)) == true


# move : m ∈ [0,9]² 
# direction : d ∈ {-1, 1}
# is move forward : (m₁ + m₂) ⋅ d ≥ 0
is_move_forward(m :: Array{Int8}, d :: Int8) = diagonal_projection(m) ⋅ d ≥ 0

# unit tests
is_move_forward(map(Int8, [ 1  1]), Int8(1) ) == true
is_move_forward(map(Int8, [-1  1]), Int8(1))  == true
is_move_forward(map(Int8, [-1 -1]), Int8(1))  == false
is_move_forward(map(Int8, [-1 -1]), Int8(-1)) == true
is_move_forward(map(Int8, [-1 1]), Int8(-1))  == true
is_move_forward(map(Int8, [-1  -1]), Int8(1)) == false
is_move_forward(map(Int8, [0  0]), Int8(1))   == true

# start unit moves : Ω₀ = {ω | ω ∈  Ω, is_move_forward(ω, 1)}
Ω₀ = filter(m -> is_move_forward(m, Int8(1)), unit_moves)

# target unit moves : Ω₁ = {ω | ω ∈  Ω, is_move_forward(ω, -1)}
Ω₁ = filter(m -> is_move_forward(m, Int8(-1)), unit_moves)

# position : p ∈ [0,9]² 
# is position valid : (p ∈ [0,9]²) & (p ∉ P₀ ∪ P₁) 
is_position_valid(r :: Array{Int8}) = is_position_in_bounds(r) & is_position_open(r)


# position : p ∈ [0,9]² 
# direction : d ∈ {-1, 1}
get_unit_moves(r :: Array{Int8}, d :: Int8) = filter(m -> is_position_valid(r + m), d == 1 ? Ω₀ : Ω₁)


# unit test
get_unit_moves(map(Int8, [1 1]), Int8(1)) == []
get_unit_moves(map(Int8, [2 2]), Int8(1)) == []
get_unit_moves(map(Int8, [3 2]), Int8(1)) == [[1 0], [0 1]]

# position : p ∈ [0,9]² 
# move : m ∈ [0,9]²  
is_double_move_open(r :: Array{Int8}, m :: Array{Int8}) = (~is_position_open(r + m)) & is_position_valid(map(Int8, r + 2*m))

# unit tests
is_double_move_open(map(Int8, [1 1]), map(Int8, [1 0])) == false
is_double_move_open(map(Int8, [3 1]), map(Int8, [1 0])) == true


# position : p ∈ [0,9]² 
# direction : d ∈ {-1, 1}
function get_double_moves(r :: Array{Int8}, d :: Int8) 
    visited_moves = Set()
    moves_queue   = [map(Int8, [0 0])]
    while length(moves_queue) > 0
        moves = map( m -> map( n -> map(Int8,2*n), filter( u -> is_double_move_open(r + m, u), Ω) ), moves_queue)
        moves = filter(m -> is_move_forward(m, d), collect(Iterators.flatten(moves)))
        moves_queue = setdiff(moves, visited_moves)
        visited_moves = union(visited_moves, moves)
        break
    end
    return collect(visited_moves) 
end

# unit tests
get_double_moves(map(Int8, [3 1]), Int8(1)) == [[2 0], [0 2]]
get_double_moves(map(Int8, [1 3]), Int8(1)) == [[2 0], [0 2]]

# positions : P ∈ [0,9]²ˣ¹⁰
# index : i ∈ Ζ
# position : p ∈ [0,9]² 
function replace_position(R :: Array{Matrix{Int8}}, i :: Int8, r :: Array{Int8})
    S = copy(R)
    S[i] = R
    return S
end

# unit test
replace_position(P₀, Int8(4), map(Int8, [2 4])) == map(p -> map(Int8, p), [
    [1 1], [1 2], [2 1], [2 4], [2 2], [1 3], [4 1],
    [3 2], [2 3], [1 4]
])


# active positions : Q ∈ [0,9]²ˣ¹⁰
# direction : d ∈ {-1, 1}
function get_next_positions(R :: Vector{Matrix{Int8}}, d :: Int8)
    return collect(
        Iterators.flatten(
            map(
                ((i, r), ) -> map(
                    m -> replace_position(R, Int8(i), r + m), 
                    vcat(
                        get_unit_moves(r, d), 
                        get_double_moves(r, d))
                    ), 
                enumerate(R)
            )
        )
    )
end

# unit tests 
length(get_next_positions(P₀, Int8(1)))  == 14
length(get_next_positions(P₁, Int8(-1))) == 14

# active positions : R₀ ∈ [0,9]²ˣ¹⁰
# other positions : R₁ ∈ [0,9]²ˣ¹⁰
# direction : d ∈ {-1, 1}
function get_position_transitions(R₀ :: Array{Matrix{Int8}}, R₁ :: Array{Matrix{Int8}}, d :: Int8)
    return Array([R₀, R₁, get_next_positions(R₀, d)])
end

# unit tests
length(get_position_transitions(P₀, P₁, Int8(1))[3]) == 14
length(get_position_transitions(P₁, P₀, Int8(-1))[3]) == 14

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

active_player_for_turn(turn) = 2 - (turn % 2)

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
Int8(1) :: Int8
main(1)




