# BiometricTables.jl

[![Build Status](https://github.com/thfreud/BiometricTables.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/thfreud/BiometricTables.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/thfreud/BiometricTables.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/thfreud/BiometricTables.jl)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)
[![Aqua QA](https://juliatesting.github.io/Aqua.jl/dev/assets/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)
[![Docs (dev)](https://img.shields.io/badge/docs-dev-blue.svg)](https://seu-usuario.github.io/BiometricTables.jl/dev/)

> **Status do Projeto:** Em desenvolvimento ativo (`WIP`). As interfaces e APIs podem sofrer alterações até o lançamento da primeira versão estável (`v0.1.0`).

O **`BiometricTables.jl`** é um pacote em Julia projetado para catalogar, manipular e consultar **tábuas biométricas atuariais**. Ele fornece estruturas de dados otimizadas e uma interface baseada em **múltiplo despacho** para gerenciar tanto tábuas de decremento único (mortalidade) quanto tábuas de múltiplos decrementos (mortalidade, invalidez, aposentadoria, desligamento/rotatividade).

---

## Recursos Principais
- **Conversão Automática:** Construtor de fábrica para `MultiDecrementTable` que combina tábuas independentes ($q'_x$) em probabilidades dependentes ($q_x^{(d)}$) sob a hipótese de distribuição uniforme dos decrementos ou de força de mortalidade constante. 

---

## Estrutura do Domínio

- `AbstractBiometricTable`: Tipo abstrato base para todas as tábuas biométricas.
  - `SingleDecrementTable`: Tábua de decremento único (mortalidade/invalidez individual). Acompanha metadados estruturados.
  - `MultiDecrementTable`: Tábua combinada para múltiplos decrementos simultâneos.
- `AbstractDecrement`: Tipo abstrato para causas de saída.
  - `Death()`, `Disability()`, `Retirement()`, `Termination()`.

---

## Exemplo Rápido de Uso

```julia
using BiometricTables

# 1. Definição de Metadados e Tábua de Mortalidade
meta = MetaData(
    source = "IBA",
    name = "AT-2000 Male",
    description = "Tábua de Mortalidade Geral",
    publication_year = 2000
)

ages_vec = collect(18:115)
rates_vec = [...] # Vetor de qx

mt = SingleDecrementTable(rates_vec, ages_vec, meta, Death(), Male())

# Consultas básicas
q_30 = qx(mt, 30)          # Taxa de mortalidade aos 30 anos
p_30 = px(mt, 30)          # Probabilidade de sobrevivência (1 - qx)
s_10 = survival(mt, 30, 10) # Probabilidade de sobreviver por 10 anos (10_p_30)

# 2. Construção de Tábua de Múltiplos Decrementos
mdt = MultiDecrementTable(
    collect(18:75),
    tabua_morte,
    tabua_rotatividade,
    tabua_aposentadoria,
    tabua_invalidez
)

# Consulta por decremento específico q_x^(d)
q_morte_30 = qx(mdt, 30, Death())
q_inval_30 = qx(mdt, 30, Disability())

# Probabilidade global de saída q_x^(τ) e sobrevivência conjunta p_x^(τ)
q_total_30 = qx(mdt, 30)
p_total_30 = px(mdt, 30)
```
## Principais Funções da API

| Função | Assinatura / Descrição |
| :--- | :--- |
| `qx(table, age)` | Retorna a probabilidade de saída na idade especificada (qx ou qx(τ)). |
| `qx(mdt, age, decrement)` | Retorna a probabilidade dependente para um decremento específico qx(d). |
| `px(table, age)` | Retorna a probabilidade de sobrevivência no ano de idade (px = 1 - qx). |
| `survival(table, age, time)` | Retorna a probabilidade de sobrevivência ao longo de t anos (t px). |
| `ages(table)` | Retorna o vetor de idades cobertas pela tábua. |
| `minimum_age(table)` / `maximum_age(table)` | Retorna a menor e a maior idade presentes na tábua. |
| `metadata(mt)` | Retorna os metadados de uma MortalityTable. |

