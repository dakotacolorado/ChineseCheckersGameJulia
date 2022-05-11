module ChineseCheckers

    export 
        p1_start_positions,
        p2_start_positions,
        p1_target_positions,
        p2_target_positions,
        start_game_state,
        unit_moves,
        start_turn,
        is_point_in_bounds, 
        is_position_in_bounds, 
        is_position_open,
        is_position_valid,
        get_unit_moves,
        is_double_move_open,
        get_double_moves,
        get_player_for_turn,
        get_postitions_for_player,
        get_next_moves,
        update_game_state,
        get_next_game_states,
        is_game_won

    include("rule_engine.jl")
    include("game_model.jl")
end