module BiometricTables

export px, qx, survival, ages, 
minimum_age, maximum_age, metadata, 
MultiDecrementTable, SingleDecrementTable, MetaData, gender

include("Types.jl")
include("Interface.jl")
include("Display.jl")

end
