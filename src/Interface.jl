# --- Interface para MortalityTable ---
include("Types.jl")

ages(mt::MortalityTable) = mt.ages
minimum_age(mt::MortalityTable) = minimum(ages(mt))
maximum_age(mt::MortalityTable) = maximum(ages(mt))
metadata(mt::MortalityTable) = mt.metadata

@inline function _age_index(mt::MortalityTable, age::Int)
    idx = age - minimum_age(mt) + 1
    @boundscheck checkbounds(mt.rates, idx)
    return idx
end

function qx(mt::MortalityTable, age::Int)::Float64
    idx = _age_index(mt, age)
    return @inbounds mt.rates[idx]
end

px(mt::MortalityTable, age::Int)::Float64 = 1.0 - qx(mt, age)

"""
    survival(mt::MortalityTable, age::Int, time::Int)::Float64

Retorna a probabilidade de sobrevivência t_p_x ao longo de `time` anos.
"""
function survival(mt::MortalityTable, age::Int, time::Int)::Float64
    p = 1.0
    for t_age in 0:(time - 1)
        p *= px(mt, age + t_age)
    end
    return p
end


# --- Interface para MultiDecrementTable ---

ages(mdt::MultiDecrementTable) = mdt.ages
minimum_age(mdt::MultiDecrementTable) = minimum(ages(mdt))
maximum_age(mdt::MultiDecrementTable) = maximum(ages(mdt))

@inline function _age_index(mdt::MultiDecrementTable, age::Int)
    idx = age - minimum_age(mdt) + 1
    @boundscheck checkbounds(mdt.ages, idx)
    return idx
end

# Auxiliares para resolução de despacho por decremento
@inline _rates(mdt::MultiDecrementTable, ::Death)       = mdt.mortality_probabilities
@inline _rates(mdt::MultiDecrementTable, ::Termination) = mdt.turnover_probabilities
@inline _rates(mdt::MultiDecrementTable, ::Retirement)  = mdt.retirement_probabilities
@inline _rates(mdt::MultiDecrementTable, ::Disability)  = mdt.disability_probabilities

"""
    qx(mdt::MultiDecrementTable, age::Int, d::AbstractDecrement)::Float64

Retorna a probabilidade dependente q_x^(d) para o decremento específico `d`.
"""
function qx(mdt::MultiDecrementTable, age::Int, d::AbstractDecrement)::Float64
    idx = _age_index(mdt, age)
    vec = _rates(mdt, d)
    return @inbounds vec[idx]
end

"""
    qx(mdt::MultiDecrementTable, age::Int)::Float64

Retorna a probabilidade total de saída por qualquer causa (q_x^(τ)).
"""
function qx(mdt::MultiDecrementTable, age::Int)::Float64
    return qx(mdt, age, Death()) +
           qx(mdt, age, Termination()) +
           qx(mdt, age, Retirement()) +
           qx(mdt, age, Disability())
end

px(mdt::MultiDecrementTable, age::Int)::Float64 = 1.0 - qx(mdt, age)

"""
    survival(mdt::MultiDecrementTable, age::Int, time::Int)::Float64

Retorna a probabilidade de sobrevivência conjunta a todos os decrementos ao longo de `time` anos.
"""
function survival(mdt::MultiDecrementTable, age::Int, time::Int)::Float64
    p = 1.0
    for t_age in 0:(time - 1)
        p *= px(mdt, age + t_age)
    end
    return p
end