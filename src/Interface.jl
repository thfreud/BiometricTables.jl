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

Retorna a probabilidade de sobrevivência ``{_t}p_x`` ao longo de `time` anos, implementada através da fórmula:
```math
{_t}p_{x} = \\prod_{k=0}^{t-1}p_{x+k}
```
"""
function survival(mt::SingleDecrementTable, age::Int, time::Int)::Float64
    if age+time > maximum_age(mt)
        throw(ArgumentError("Idade + time - 1 não podem ultrapassar o horizonte da tábua: $(maximum_age(mt))"))
    end
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
@inline _rates(mdt::MultiDecrementTable, d::AbstractDecrement) = mdt.rates[d]

"""
    qx(mdt::MultiDecrementTable, age::Int, d::AbstractDecrement)::Float64

Retorna a probabilidade dependente \$q_x^{(d)}\$ para o decremento específico `d`.
"""
function qx(mdt::MultiDecrementTable, age::Int, d::AbstractDecrement)::Float64
    idx = _age_index(mdt, age)
    vec = _rates(mdt, d)
    return @inbounds vec[idx]
end

"""
    qx(mdt::MultiDecrementTable, age::Int)::Float64

Retorna a probabilidade total de saída por qualquer causa \$q_x^{(\\tau)}\$.
"""
function qx(mdt::MultiDecrementTable, age::Int)::Float64
    total = sum(qx(mdt, age, d) for d in keys(mdt.rates))
    if total > 1
        @warn "A soma total dos decrementos na idade $(age) ultrapassa 1.0"
        return 1.0
    end
    return total
end

"""
    px(mdt::MultiDecrementTable, age::Int)::Float64

Retorna a probabilidade de sobrevivência em ambiente multidecremental.
"""
px(mdt::MultiDecrementTable, age::Int)::Float64 = 1.0 - qx(mdt, age)


"""
    survival(mdt::MultiDecrementTable, age::Int, time::Int)::Float64

Retorna a probabilidade de sobrevivência conjunta a todos os decrementos ao longo de `time` anos.
```math
{_t}p_{x}^{\\tau} = \\prod_{k=0}^{t-1}p_{x+k}^{\\tau}
```
"""
function survival(mdt::MultiDecrementTable, age::Int, time::Int)::Float64
    p = 1.0
    for t_age in 0:(time-1)
        p *= px(mdt, age + t_age)
    end
    return p
end

# Conversão de decrementos independentes para probabilidades decrementais utilizando hipótese
# de Força de Mortalidade Constante.

function _convert_rates(
    rates::Dict{D, Vector{Float64}}, 
    ::ConstantForce) where {D <: AbstractDecrement}
    
    dec_keys = collect(keys(rates))
    n = length(rates[first(dec_keys)])
    
    # Inicializa o dicionário de saída com vetores zerados
    converted = Dict{D, Vector{Float64}}(d => zeros(n) for d in dec_keys)

    @inbounds for k in 1:n
        # Calcula p_tau para a idade k
        p_tau = 1.0
        for d in dec_keys
            p_tau *= (1.0 - rates[d][k])
        end
        
        q_tau = 1.0 - p_tau

        if q_tau > 0.0 && p_tau > 0.0
            ln_p_tau = log(p_tau)
            for d in dec_keys
                q_ind = rates[d][k]
                if q_ind < 1.0
                    converted[d][k] = q_tau * (log(1.0 - q_ind) / ln_p_tau)
                else
                    # Caso de borda: taxa independente de 100%
                    converted[d][k] = 1.0
                end
            end
        end
    end

    return converted
end


#Converte taxas independentes \$q'\$ em probabilidades dependentes \$q\$ via a expansão 
#polinomial exata da integral sob a hipótese de Distribuição Uniforme de Decrementos (UDD) 
#aplicada individualmente.
function _convert_rates(
    rates::Dict{D, Vector{Float64}}, 
    ::UDDIndividual) where {D <: AbstractDecrement}
    
    dec_keys = collect(keys(rates))
    n = length(rates[first(dec_keys)])
    converted = Dict{D, Vector{Float64}}(d => zeros(n) for d in dec_keys)

    # Pontos e pesos de Quadratura de Gauss-Legendre para integral no intervalo [0, 1]
    # Avalia a integral \int_0^1 \prod_{i \neq j} (1 - t * q'_i) dt
    nodes = (0.5 - sqrt(15)/10, 0.5, 0.5 + sqrt(15)/10)
    weights = (5/18, 8/18, 5/18)

    @inbounds for k in 1:n
        for j_dec in dec_keys
            q_j = rates[j_dec][k]
            other_decs = [d for d in dec_keys if d !== j_dec]
            
            # Aproximação do valor da integral \int_0^1 \prod_{d \neq j} (1 - t * q'_d) dt
            integral_val = 0.0
            for (t, w) in zip(nodes, weights)
                prod_others = 1.0
                for d in other_decs
                    prod_others *= (1.0 - t * rates[d][k])
                end
                integral_val += w * prod_others
            end
            
            converted[j_dec][k] = q_j * integral_val
        end
    end

    return converted
end

"""
    MultiDecrementTable(
    tables::SingleDecrementTable...;
    method::ConversionMethod = UDDIndividual()
)

Constrói uma `MultiDecrementTable` a partir de quatro tábuas de decremento único (independentes),
convertendo as taxas ``q'^{(j)}_x`` em probabilidades dependentes ``q^{(j)}_x`` via o método especificado 
(`UDDIndividual()` ou `ConstantForce()`).
## Conversão de Decrementos em Probabilidades
A conversão de taxas decrementais indepentendentes para probabilidades em ambiente de múltiplos decrementos aceita dois métodos básicos.
A Força de Mortalidade Constante também depende da hipótese UDD.

- Força de Mortalidade Constante. `ConstantForce`

```math
    q_x^{(j)} = q_x^{(\tau)}\frac{\\log(1-q_x^{s(j)})}{\\log(1-q_x^{\tau})}.
```

- Distribuição Uniforme de Decrementos (UDD) `UDDIndividual`

```math
    q_x^{(j)} = q_x^{s(j)}\\int_0^1\\prod_{i\neq j}(1-tq_x^{s(j)})dt.
```
"""
function MultiDecrementTable(
    tables::SingleDecrementTable...;
    method::ConversionMethod=UDDIndividual()
)
    isempty(tables) && throw(ArgumentError("Forneça ao menos uma tábua de decremento."))

    base_ages = ages(tables[1])
    base_gender = gender(tables[1])

    for t in tables
        if ages(t) != base_ages
            throw(ArgumentError("Todas as tábuas devem possuir exatamente o mesmo intervalo de idades."))
        end
        if gender(t) != base_gender
            @warn "As tábuas associadas possuem gêneros distintos."
        end
    end

    dict_rates = Dict(t.decrement => rates(t) for t in tables)
    converted_rates = _convert_rates(dict_rates, method)

    return MultiDecrementTable(
        base_ages,
        converted_rates,
        base_gender
    )
end
