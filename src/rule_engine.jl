using StaticArrays
using Base.Iterators

# diagonal projection : p₁ + p₂
function diagonal_projection(
    position :: SVector{2, Int8}
    ) 
    return position[1] + position[2]
end

# perpendicular projection : p₁ - p₂
function perpendicular_projection(
    position :: SVector{2, Int8}
    ) 
    return position[1] - position[2]
end 

# point : pᵢ ∈ [1,9]
function is_point_in_bounds(
    point :: Int8
    ) 
    return (point ≥ Int8(1)) & (point ≤ Int8(9))
end

# position : p ∈ [1,9]²
function is_position_in_bounds(
    position :: SVector{2, Int8}
    ) 
    return is_point_in_bounds(position[1]) & is_point_in_bounds(position[2])
end

# position : p ∈ [1,9]²
# Positions : P ∈ [0,9]²ˣ¹⁰
# is position open : p ∉ P₀ ∪ P₁
function is_position_open(
    position :: SVector{2, Int8}, 
    Positions :: SVector{20, SVector{2, Int8}}
    ) 
    return  ~ mapreduce(q -> q == position, |, Positions)
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

# position : p ∈ [0,9]² 
# Positions : P ∈ [0,9]²ˣ¹⁰
# is position valid : (p ∈ [0,9]²) & (p ∉ P₀ ∪ P₁) 
function is_position_valid(
    position ::SVector{2, Int8}, 
    Positions :: SVector{20, SVector{2, Int8}}
    ) 
    is_valid =  is_position_in_bounds(position)
    is_valid &= is_position_open(position, Positions)
    return is_valid
end

# unit moves : Ω = {(m₁, m₂) | mᵢ ∈ {-1, 0, 1}, m₁ + m₂ ≤ 2}
unit_moves = SVector{6}(map(
    m -> SVector{2}(Int8(m[1]), Int8(m[2])),
    [ 
        [1 0], [-1 0], [0 1], [0 -1], [-1 1], [1 -1]
    ]
))

# position : p ∈ [0,9]² 
# Positions : P ∈ [0,9]²ˣ¹⁰
# get unit moves : {ω | ω ∈ Ω, p + ω ∉ P, p + ω ∈ [0,9]²}
function get_unit_moves(
    position :: SVector{2, Int8}, 
    Positions :: SVector{20, SVector{2, Int8}}
    ) 
    return filter(
        move -> is_position_valid(position + move, Positions), 
        unit_moves
    )
end

# position : p ∈ [0,9]² 
# move : m ∈ [0,9]²
# Positions : P ∈ [0,9]²ˣ¹⁰
# is double move open : (p + m ∈ P) & (p + 2*m ∉ P) & (p + 2*m ∈ [0,9]²)
function is_double_move_open(
    position :: SVector{2, Int8}, 
    move :: SVector{2, Int8}, 
    Positions :: SVector{20, SVector{2, Int8}}
    ) 
    is_open = ~is_position_open(position + move, Positions)
    is_open &= is_position_valid(map(Int8, position + 2*move), Positions)
    return is_open
end

# position : p ∈ [0,9]² 
# Positions : P ∈ [0,9]²ˣ¹⁰
function get_double_moves(
    position :: SVector{2, Int8}, 
    Positions :: SVector{20, SVector{2, Int8}}
    ) 
    visited_moves = Set{SVector{2, Int8}}()
    moves_queue   = Array{SVector{2, Int8}}([SVector(Int8(0), Int8(0))])
   
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

# new_position : p ∈ [0,9]² 
# index : i ∈ [0,9]
# Positions : P ∈ [0,9]²ˣ¹⁰
function replace_position(
    new_position :: SVector{2, Int8},
    index :: Int8, 
    Positions :: SVector{10, SVector{2, Int8}}
    )
    return SVector{10}(map(
        ((j, position), ) -> j == index ? new_position : position, 
        enumerate(Positions)
    ))
end

# active Positions : R ∈ [0,9]²ˣ¹⁰
# Positions : R ∈ [0,9]²ˣ²⁰
# direction : d ∈ {-1, 1}
function get_next_positions(
    active_Positions :: SVector{10, SVector{2, Int8}}, 
    Positions :: SVector{20, SVector{2, Int8}}
    )
    return collect(
        Iterators.flatten(
            map(
                ((i, position), ) -> map(
                    move -> replace_position(active_Positions, Int8(i), position + move), 
                    vcat(
                        get_unit_moves(position, Positions), 
                        get_double_moves(position, Positions))
                    ), 
                enumerate(active_Positions)
            )
        )
    )
end

