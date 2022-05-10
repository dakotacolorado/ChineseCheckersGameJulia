module ChineseCheckers

    export is_point_in_bounds, 
        is_position_in_bounds, 
        diagonal_projection,
        perpendicular_projection,
        is_position_open,
        is_move_forward,
        is_position_valid,
        get_unit_moves,
        is_double_move_open,
        get_double_moves,
        replace_position,
        get_next_positions

    include("rule_engine.jl")
    include("game_model.jl")
end