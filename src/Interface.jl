# --- Interface para MortalityTable ---
ages(mt::SingleDecrementTable) = mt.ages
minimum_age(mt::SingleDecrementTable) = minimum(ages(mt))
maximum_age(mt::SingleDecrementTable) = maximum(ages(mt))
metadata(mt::SingleDecrementTable) = mt.metadata
decrement(mt::SingleDecrementTable) = mt.decrement
rates(mt::SingleDecrementTable) = mt.rates
gender(mt::SingleDecrementTable) = mt.gender

@inline function _age_index(mt::SingleDecrementTable, age::Int)
    idx = age - minimum_age(mt) + 1
    @boundscheck checkbounds(mt.rates, idx)
    return idx
end

function qx(mt::SingleDecrementTable, age::Int)::Float64
    idx = _age_index(mt, age)
    return @inbounds mt.rates[idx]
end

px(mt::SingleDecrementTable, age::Int)::Float64 = 1.0 - qx(mt, age)

"""
    survival(mt::SingleDecrementTableble, age::Int, time::Int)::Float64

Retorna a probabilidade de sobrevivência \$t_p_x\$ ao longo de `time` anos.
"""
function survival(mt::SingleDecrementTable, age::Int, time::Int)::Float64
    p = 1.0
    for t_age in 0:(time-1)
        p *= px(mt, age + t_age)
    end
    return p
end


# --- Interface para MultiDecrementTable ---

ages(mdt::MultiDecrementTable) = mdt.ages
minimum_age(mdt::MultiDecrementTable) = minimum(ages(mdt))
maximum_age(mdt::MultiDecrementTable) = maximum(ages(mdt))
gender(mdt::MultiDecrementTable) = mdt.gender

@inline function _age_index(mdt::MultiDecrementTable, age::Int)
    idx = age - minimum_age(mdt) + 1
    @boundscheck checkbounds(mdt.ages, idx)
    return idx
end

# Auxiliares para resolução de despacho por decremento
@inline _rates(mdt::MultiDecrementTable, ::Death) = mdt.mortality_probabilities
@inline _rates(mdt::MultiDecrementTable, ::Termination) = mdt.turnover_probabilities
@inline _rates(mdt::MultiDecrementTable, ::Retirement) = mdt.retirement_probabilities
@inline _rates(mdt::MultiDecrementTable, ::Disability) = mdt.disability_probabilities

"""
    qx(mdt::MultiDecrementTable, age::Int, d::AbstractDecrement)::Float64

Retorna a probabilidade dependente \$q_x^(d)\$ para o decremento específico `d`.
"""
function qx(mdt::MultiDecrementTable, age::Int, d::AbstractDecrement)::Float64
    idx = _age_index(mdt, age)
    vec = _rates(mdt, d)
    return @inbounds vec[idx]
end

"""
    qx(mdt::MultiDecrementTable, age::Int)::Float64

Retorna a probabilidade total de saída por qualquer causa \$q_x^(τ)\$.
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
    for t_age in 0:(time-1)
        p *= px(mdt, age + t_age)
    end
    return p
end


"""
    _convert_rates(
    q_d::Vector{Float64}, q_t::Vector{Float64},
    q_r::Vector{Float64}, q_i::Vector{Float64},
    ::ConstantForce
)

Conversão de decrementos independentes para probabilidades decrementais utilizando hipótese
de Força de Mortalidade Constante.
\$\$ q_x^{(j)} = q_x^{s(j)}\\int_0^1\\prod_{i\\neq j}(1-tq_x^{s(j)})dt\$\$
"""
function _convert_rates(
    q_d::Vector{Float64}, q_t::Vector{Float64},
    q_r::Vector{Float64}, q_i::Vector{Float64},
    ::ConstantForce
)
    n = length(q_d)
    dep_d, dep_t, dep_r, dep_i = zeros(n), zeros(n), zeros(n), zeros(n)

    @inbounds for k in 1:n
        qd, qt, qr, qi = q_d[k], q_t[k], q_r[k], q_i[k]

        # p_tau produto das sobrevivências independentes
        p_tau = (1.0 - qd) * (1.0 - qt) * (1.0 - qr) * (1.0 - qi)
        q_tau = 1.0 - p_tau

        if q_tau > 0.0
            ln_p_tau = log(p_tau)
            dep_d[k] = q_tau * (log(1.0 - qd) / ln_p_tau)
            dep_t[k] = q_tau * (log(1.0 - qt) / ln_p_tau)
            dep_r[k] = q_tau * (log(1.0 - qr) / ln_p_tau)
            dep_i[k] = q_tau * (log(1.0 - qi) / ln_p_tau)
        end
    end
    return Dict(
        Death() => dep_d,
        Termination() => dep_t,
        Retirement() => dep_r,
        Disability() => dep_i
    )

end


@inline _s1(x, y, z) = x + y + z
@inline _s2(x, y, z) = x*y + x*z + y*z
@inline _s3(x, y, z) = x*y*z

@inline _udd_kernel(w, x, y, z) = w * (1.0 - 0.5 * _s1(x, y, z) + (1/3) * _s2(x, y, z) - 0.25 * _s3(x, y, z))

@inline function _convert_4_decrements_udd(qd, qt, qr, qi)
    dep_d = _udd_kernel(qd, qt, qr, qi)
    dep_t = _udd_kernel(qt, qd, qr, qi)
    dep_r = _udd_kernel(qr, qd, qt, qi)
    dep_i = _udd_kernel(qi, qd, qt, qr)
    return dep_d, dep_t, dep_r, dep_i
end


"""
    _convert_rates(q_d, q_t, q_r, q_i, ::UDDIndividual)

Converte taxas independentes \$q'\$ em probabilidades dependentes \$q\$ via a expansão 
polinomial exata da integral sob a hipótese de Distribuição Uniforme de Decrementos (UDD) 
aplicada individualmente.
"""
function _convert_rates(
    q_d::Vector{Float64}, q_t::Vector{Float64},
    q_r::Vector{Float64}, q_i::Vector{Float64},
    ::UDDIndividual
)
    n = length(q_d)
    dep_d, dep_t, dep_r, dep_i = zeros(n), zeros(n), zeros(n), zeros(n)

    @inbounds for k in 1:n
        dep_d[k], dep_t[k], dep_r[k], dep_i[k] = _convert_4_decrements_udd(
            q_d[k], q_t[k], q_r[k], q_i[k]
        )
    end

    return Dict(
        Death() => dep_d,
        Termination() => dep_t,
        Retirement() => dep_r,
        Disability() => dep_i
    )
end

"""
    MultiDecrementTable(
    dt_death::SingleDecrementTable,
    dt_turnover::SingleDecrementTable,
    dt_retirement::SingleDecrementTable,
    dt_disability::SingleDecrementTable;
    method::ConversionMethod = UDDIndividual()
)

Constrói uma `MultiDecrementTable` a partir de quatro tábuas de decremento único (independentes),
convertendo as taxas \$q'^{(j)}_x\$ em probabilidades dependentes \$q^{(j)}_x\$ via o método especificado 
(`UDDIndividual()` ou `ConstantForce()`).
"""
function MultiDecrementTable(
    dt_death::SingleDecrementTable,
    dt_turnover::SingleDecrementTable,
    dt_retirement::SingleDecrementTable,
    dt_disability::SingleDecrementTable;
    method::ConversionMethod=UDDIndividual()
)
    ages_d = ages(dt_death)
    if ages(dt_turnover) != ages_d || ages(dt_retirement) != ages_d || ages(dt_disability) != ages_d
        throw(ArgumentError("Todas as MortalityTables fornecidas devem possuir exatamente o mesmo intervalo de idades."))
    end

    if gender(dt_death) != gender(dt_turnover) || gender(dt_death) != gender(dt_retirement) || gender(dt_death) != gender(dt_disability)
        @warn "As tábuas associadas possuem sexos/géneros distintos."
    end

    q_d = rates(dt_death)
    q_t = rates(dt_turnover)
    q_r = rates(dt_retirement)
    q_i = rates(dt_disability)

    converted_rates = _convert_rates(q_d, q_t, q_r, q_i, method)

    return MultiDecrementTable(
        ages_d,
        converted_rates[Death()],
        converted_rates[Termination()],
        converted_rates[Retirement()],
        converted_rates[Disability()],
        gender(dt_death)
    )
end
