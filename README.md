# BiometricTables.jl

[![Build Status](https://github.com/thfreud/BiometricTables.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/thfreud/BiometricTables.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/thfreud/BiometricTables.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/thfreud/BiometricTables.jl)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)
[![Aqua QA](https://juliatesting.github.io/Aqua.jl/dev/assets/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)
[![Docs (dev)](https://img.shields.io/badge/docs-dev-blue.svg)](https://thfreud.github.io/BiometricTables.jl/dev/)

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
println("=== Teste de Construção e Conversão de MultiDecrementTable ===\n")

# 1. Configuração dos Dados de Teste (Idades de 20 a 24)
test_ages = 20:24

# Taxas independentes de exemplo (q')
q_prime_death      = [0.0010, 0.0012, 0.0015, 0.0018, 0.0020]
q_prime_turnover   = [0.0500, 0.0400, 0.0300, 0.0200, 0.0100]
q_prime_retirement = [0.0000, 0.0000, 0.0000, 0.0100, 0.0500]
q_prime_disability = [0.0005, 0.0006, 0.0008, 0.0010, 0.0012]

# Instanciação das SingleDecrementTable individuais
mock_metadata = MetaData("s", "s", "s", 2000)
mt_d = SingleDecrementTable(collect(test_ages), q_prime_death, mock_metadata, Death(), Unisex())
mt_t = SingleDecrementTable(collect(test_ages), q_prime_turnover, mock_metadata, Termination(), Unisex())
mt_r = SingleDecrementTable(collect(test_ages), q_prime_retirement, mock_metadata, Retirement(), Unisex())
mt_i = SingleDecrementTable(collect(test_ages), q_prime_disability, mock_metadata, Disability(), Unisex())

# 2. Construção via UDD Individual (Integração / Quadratura Genérica)
mdt_udd = MultiDecrementTable(mt_d, mt_t, mt_r, mt_i; method = BiometricTables.UDDIndividual())

# 3. Construção via Constant Force (Força Constante de Decremento)
mdt_cf = MultiDecrementTable(mt_d, mt_t, mt_r, mt_i; method = BiometricTables.ConstantForce())

# 4. Exibição dos Resultados Comparativos para a Idade 24
target_age = 24
println("Comparação para a Idade $target_age:")
println("--------------------------------------------------")
println("Taxas Independentes de Entrada (q'):")
println("  Death: $(qx(mt_d, target_age)) | Turnover: $(qx(mt_t, target_age)) | Retirement: $(qx(mt_r, target_age)) | Disability: $(qx(mt_i, target_age))\n")

println("Probabilidades Dependentes Calculadas (q):")
println("  [UDD Individual]")
println("    q_death      = ", qx(mdt_udd, target_age, Death()))
println("    q_turnover   = ", qx(mdt_udd, target_age, Termination()))
println("    q_retirement = ", qx(mdt_udd, target_age, Retirement()))
println("    q_disability = ", qx(mdt_udd, target_age, Disability()))
println("    q_tau (Total)= ", qx(mdt_udd, target_age))
println("    p_tau        = ", px(mdt_udd, target_age))

println("\n  [Constant Force]")
println("    q_death      = ", qx(mdt_cf, target_age, Death()))
println("    q_turnover   = ", qx(mdt_cf, target_age, Termination()))
println("    q_retirement = ", qx(mdt_cf, target_age, Retirement()))
println("    q_disability = ", qx(mdt_cf, target_age, Disability()))
println("    q_tau (Total)= ", qx(mdt_cf, target_age))
println("    p_tau        = ", px(mdt_cf, target_age))

# 5. Validação de Sobrevivência Multianual (5 anos a partir dos 20)
p_5_udd = survival(mdt_udd, 20, 5)
p_5_cf  = survival(mdt_cf, 20, 5)

println("\n--------------------------------------------------")
println("Sobrevivência Acumulada em 5 anos (5_p_20):")
println("  UDD Individual: ", p_5_udd)
println("  Constant Force: ", p_5_cf)
println("  Diferença Absoluta: ", abs(p_5_udd - p_5_cf))
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


## Comparação Visual de Tábuas

Você pode fazer uma plotagem para comparar objetos do tipo `SingleDecrementTable` através da função `plot([obj1, obj2])` ou `plot(obj)` para um único objeto.
Objetos do tipo `MultiDecrementTable` podem ser igualmente plotados, mas ainda não há uma assinatura para comparação de tábuas de múltiplos decrementos.
