using Test

# diagonal_projection
@test diagonal_projection(SVector(Int8( 0), Int8( 0)))  ==  0
@test diagonal_projection(SVector(Int8( 2), Int8( 2)))  ==  4
@test diagonal_projection(SVector(Int8(-2), Int8(-2)))  == -4

# perpendicular_projection
@test perpendicular_projection(SVector(Int8(0),Int8(0))) ==  0
@test perpendicular_projection(SVector(Int8(2),Int8(2))) ==  0
@test perpendicular_projection(SVector(Int8(2),Int8(3))) == -1
@test perpendicular_projection(SVector(Int8(3),Int8(2))) ==  1

# is_move_forward
@test is_move_forward(SVector(Int8( 1), Int8( 1)), Int8(1) ) == true
@test is_move_forward(SVector(Int8(-1), Int8( 1)), Int8(1))  == true
@test is_move_forward(SVector(Int8(-1), Int8(-1)), Int8(1))  == false
@test is_move_forward(SVector(Int8(-1), Int8(-1)), Int8(-1)) == true
@test is_move_forward(SVector(Int8(-1), Int8( 1)), Int8(-1)) == true
@test is_move_forward(SVector(Int8(-1), Int8(-1)), Int8(1))  == false
@test is_move_forward(SVector(Int8(0 ), Int8( 0)), Int8(1))  == true