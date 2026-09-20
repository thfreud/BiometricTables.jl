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

Base.@kwdef struct SingleDecrementTable{M<:MetaData, D <: AbstractDecrement, G <: Gender} <: AbstractBiometricTable
    ages::Vector{Int}
    rates::Vector{Float64}
    metadata::M
    decrement::D
    gender::G
end

struct MultiDecrementTable{G <: Gender} <: AbstractBiometricTable
    ages::Vector{Int}
    mortality_probabilities::Vector{Float64}
    turnover_probabilities::Vector{Float64}
    retirement_probabilities::Vector{Float64}
    disability_probabilities::Vector{Float64}
    gender::G
end

