using ChineseCheckers
using StaticArrays

# Approximate a function 
# 𝑓 : [0,9]¹⁰ˣ²ˣ² ↦ [0,10⁴⁰]
# ([x,y] denotes the set of integers from x to y inclusive)

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


