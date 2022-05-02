using ChineseCheckers
using Test
using StaticArrays

tests = [
    "rule_engine_tests"
]
for t in tests
   include("$(t).jl")
end