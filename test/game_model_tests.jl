using Test

# perpendicular_projection
@test perpendicular_projection(SVector(Int8(0),Int8(0))) ==  0
@test perpendicular_projection(SVector(Int8(2),Int8(2))) ==  0
@test perpendicular_projection(SVector(Int8(2),Int8(3))) == -1
@test perpendicular_projection(SVector(Int8(3),Int8(2))) ==  1