using ChineseCheckers
using StaticArrays

# diagonal projection : p₁ + p₂
function diagonal_projection(
    position :: Vector{Int8}
    ) 
    return position[1] + position[2]
end

# perpendicular projection : p₁ - p₂
function perpendicular_projection(
    position :: SVector{2, Int8}
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