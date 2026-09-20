import Base: show
using RecipesBase
# Auxiliar para formatar a string de sexo
_sex_str(s::Gender) = s == Male ? "Masculino" : s == Female ? "Feminino" : "Unissex"

# --- Show para MortalityTable ---
function Base.show(io::IO, ::MIME"text/plain", mt::SingleDecrementTable)
    println(io, "SingleDecrementTable (Tábua de Decremento Único)")
    println(io, "  ├─ Intervalo de Idades: ", minimum_age(mt), " a ", maximum_age(mt), " anos (", length(ages(mt)), " pontos)")
    println(io, "  ├─ Sexo:                ", _sex_str(gender(mt)))
    
    # Exibe informações do metadata se existirem
    meta = metadata(mt)
    name_str = meta.name
    source_str = meta.source
    println(io, "  ├─ Nome / Fonte:        ", name_str, " (", source_str, ")")
    
    # Pequena amostra das taxas (primeira e última idade)
    q_min = round(qx(mt, minimum_age(mt)); digits = 6)
    q_max = round(qx(mt, maximum_age(mt)); digits = 6)
    print(io,   "  └─ Amplitude qx:        q_", minimum_age(mt), " = ", q_min, " | q_", maximum_age(mt), " = ", q_max)
end

# --- Show para MultiDecrementTable ---
function Base.show(io::IO, ::MIME"text/plain", mdt::MultiDecrementTable)
    println(io, "MultiDecrementTable (Tábua de Múltiplos Decrementos)")
    println(io, "  ├─ Intervalo de Idades: ", minimum_age(mdt), " a ", maximum_age(mdt), " anos")
    println(io, "  ├─ Sexo:                ", _sex_str(gender(mdt)))
    println(io, "  └─ Decrementos Cobertos:")
    
    # Exibe o valor de qx na idade inicial como referência do resumo
    min_a = minimum_age(mdt)
    q_d = round(qx(mdt, min_a, Death()); digits = 6)
    q_t = round(qx(mdt, min_a, Termination()); digits = 6)
    q_r = round(qx(mdt, min_a, Retirement()); digits = 6)
    q_i = round(qx(mdt, min_a, Disability()); digits = 6)
    q_tau = round(qx(mdt, min_a); digits = 6)

    println(io, "      ├─ Death (m):        q_", min_a, " = ", q_d)
    println(io, "      ├─ Termination (t):  q_", min_a, " = ", q_t)
    println(io, "      ├─ Retirement (r):   q_", min_a, " = ", q_r)
    println(io, "      ├─ Disability (i):   q_", min_a, " = ", q_i)
    print(io,   "      └─ Total (q_tau):    q_", min_a, " = ", q_tau)
end



@recipe function f(mt::SingleDecrementTable; log_scale = false)
    x_data = ages(mt)
    y_data = [qx(mt, a) for a in x_data]

    xlabel --> "Idade (x)"
    ylabel --> "Probabilidade de Saída (qx)"
    legend --> :topleft
    
    if log_scale
        yscale --> :log10
    end

    meta_name = metadata(mt).name
    label --> meta_name

    return x_data, y_data
end


@recipe function f(mts::AbstractVector{T}; log_scale = false) where {T <: SingleDecrementTable}
    xlabel --> "Idade (x)"
    ylabel --> "Probabilidade de Saída (qx)"
    legend --> :topleft

    if log_scale
        yscale --> :log10
    end

    for mt in mts
        @series begin
            meta_name = metadata(mt).name
            label --> meta_name
            ages(mt), [qx(mt, a) for a in ages(mt)]
        end
    end
end


@recipe function f(mdt::MultiDecrementTable; show_total = true)
    x_data = ages(mdt)
    
    xlabel --> "Idade (x)"
    ylabel --> "Probabilidade Dependente (qx^d)"
    legend --> :topleft

    # Série: Morte
    @series begin
        label --> "Death (morte)"
        x_data, [qx(mdt, a, Death()) for a in x_data]
    end

    # Série: Desligamento
    @series begin
        label --> "Termination (rotatividade)"
        x_data, [qx(mdt, a, Termination()) for a in x_data]
    end

    # Série: Aposentadoria
    @series begin
        label --> "Retirement (aposentadoria)"
        x_data, [qx(mdt, a, Retirement()) for a in x_data]
    end

    # Série: Invalidez
    @series begin
        label --> "Disability (invalidez)"
        x_data, [qx(mdt, a, Disability()) for a in x_data]
    end

    # Série opcional: Total
    if show_total
        @series begin
            label --> "Total (q_tau)"
            linestyle --> :dash
            linewidth --> 2
            color --> :black
            x_data, [qx(mdt, a) for a in x_data]
        end
    end
end