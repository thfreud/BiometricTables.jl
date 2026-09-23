abstract type AbstractBiometricTable end
abstract type AbstractDecrement end

abstract type ConversionMethod end
struct ConstantForce <: ConversionMethod end
struct UDDIndividual <: ConversionMethod end

abstract type Gender end
struct Male <: Gender end
struct Female <: Gender end
struct Unisex <: Gender end


struct Death <: AbstractDecrement end
struct Disability <: AbstractDecrement end
struct Termination <: AbstractDecrement end
struct Retirement <: AbstractDecrement end

Base.@kwdef struct MetaData{S<:String,J<:Int}
    source::S
    name::S
    description::S
    publication_year::J
end

"""
    SingleDecrementTable(ages::Vector{Int}, rates::Vector{Float64}, metadata::MetaData, decrement::AbstractDecrement, gender::Gender)

Representa uma tábua biométrica de decremento único (ex: tábua de mortalidade, invalidez ou rotatividade).

# Campos
- `ages::Vector{Int}`: Vetor com o intervalo de idades coberto pela tábua.
- `rates::Vector{Float64}`: Vetor com as taxas/probabilidades de decremento (``q_x``).
- `metadata::M`: Metadados da tábua (nome, fonte, ano, etc.).
- `decrement::D`: Tipo de decremento (`Death()`, `Disability()`, etc.).
- `gender::G`: Gênero associado (`Male()`, `Female()`, `Unisex()`).

# Funções de Acesso (Getters)
As seguintes funções de conveniência estão disponíveis para consultar uma `SingleDecrementTable`:
- `ages(mt)`: Retorna o vetor de idades.
- `minimum_age(mt)` / `maximum_age(mt)`: Retornam os limites de idade da tábua.
- `rates(mt)`: Retorna o vetor de taxas.
- `decrement(mt)`: Retorna o tipo de decremento.
- `gender(mt)`: Retorna o gênero.
- `metadata(mt)`: Retorna os metadados.
"""
Base.@kwdef struct SingleDecrementTable{M<:MetaData, D <: AbstractDecrement, G <: Gender} <: AbstractBiometricTable
    ages::Vector{Int}
    rates::Vector{Float64}
    metadata::M
    decrement::D
    gender::G
end

# trocar os campos de taxas por um dicionário
struct MultiDecrementTable{G <: Gender, D <: AbstractDecrement} <: AbstractBiometricTable
    ages::Vector{Int}
    rates::Dict{D, Vector{Float64}}
    gender::G
end

