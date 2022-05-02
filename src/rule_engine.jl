using StaticArrays

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

# unit moves : Ω = {(m₁, m₂) | mᵢ ∈ {-1, 0, 1}, m₁ + m₂ ≤ 2}
unit_moves = SVector{6}(map(
    m -> SVector{2}(Int8(m[1]), Int8(m[2])),
    [ 
        [1 0], [-1 0], [0 1], [0 -1], [-1 1], [1 -1]
    ]
))

# start positions : P₀ = {(p₁, p₂) | pᵢ ∈ [1, 9], p₁ + p₂ ≤ 5}
start_positions =  SVector{10}(map(
    p -> SVector{2}(Int8(p[1]), Int8(p[2])),
    [ 
        [1 1], [1 2], [2 1], [3 1], [2 2],
        [1 3], [4 1], [3 2], [2 3], [1 4]
    ]
))

# target positions : P₁ = {(p₁, p₂) | pᵢ ∈ [1, 9], p₁ + p₂ ≥ 13}
target_positions = map(
    p -> SVector{2}(Int8(10 - p[1]), Int8(10 - p[2])), 
    start_positions
)

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
    Positions :: SVector{20, SVector{2, Int8}}
    ) 
    return filter(
        move -> is_position_valid(position + move, Positions), 
        unit_moves
    )
end