# interface  para MortalityTable
include("Types.jl")

@inline function _age_index(mt::MortalityTable, age::Int)
    idx = age - minimum_age(mt) + 1
    @boundscheck checkbounds(mt.rates, idx)
    return idx
end

ages(mt::MortalityTable) = mt.ages

minimum_age(mt::MortalityTable) = minimum(ages(mt))

maximum_age(mt::MortalityTable) = maximum(ages(mt))

metadata(mt::MortalityTable) = mt.metadata

function qx(mt::MortalityTable, age::Int)::Float64
    idx = _age_index(mt, age)
    return @inbounds mt.rates[idx]
end

px(mt::MortalityTable, age::Int)::Float64 = 1.0 - qx(mt, age)


"""
    survival(mt::MortalityTable, age::Int, time::Int)::Float64

TBW
"""
function survival(mt::MortalityTable, age::Int, time::Int)::Float64
    p = 1.0
    for t_age in 0:(time-1)
        p *= px(mt, age + t_age)
    end
    return p
end