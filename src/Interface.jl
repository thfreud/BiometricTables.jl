# interface de acesso aos campos
include("Types.jl")

ages(mt::MortalityTable) = mt.ages
minimum_age(mt::MortalityTable) = minimum(ages(mt))
maximum_age(mt::MortalityTable) = maximum(ages(mt))
metadata(mt::MortalityTable) = mt.metadata