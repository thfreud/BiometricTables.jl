abstract type AbstractBiometricTable end
abstract type AbstractDecrement end

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

Base.@kwdef struct SingleDecrementTable{M<:MetaData, D <: AbstractDecrement} <: AbstractBiometricTable
    ages::Vector{Int}
    rates::Vector{Float64}
    metadata::M
    decrement::D
end

struct MultiDecrementTable <: AbstractBiometricTable
    ages::Vector{Int}
    mortality_probabilities::Vector{Float64}
    turnover_probabilities::Vector{Float64}
    retirement_probabilities::Vector{Float64}
    disability_probabilities::Vector{Float64}
end

abstract type ConversionMethod end
struct ConstantForce <: ConversionMethod end
struct UDDIndividual <: ConversionMethod end