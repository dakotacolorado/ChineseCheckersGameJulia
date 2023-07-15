# base9 to binary
# encode game state : [1,9]⁴⁰ ↦ [0,1]¹²⁸
function encode_game_state(
    game_state :: Vector{Vector{Int8}}
    )
    flat_state = reduce(vcat, game_state)
    return mapreduce(
        e->(UInt128(9)^(e[1]-1)*(e[2]-1)),
        +,
        enumerate(flat_state)
    )
end

function write_game_state_features(
    filename :: String,
    game_state_features :: Dict{UInt128, Vector{}}
    )
    save(filename, "data", game_state_features)
end

function read_game_state_features(
    filename :: String
    )
    return load(filename)["data"]
end
