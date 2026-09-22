using Test
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
mt_d = SingleDecrementTable(collect(test_ages), q_prime_death, MetaData("s", "s", "s", 2000), Death(), Unisex())
mt_t = SingleDecrementTable(collect(test_ages), q_prime_turnover, MetaData("s", "s", "s", 2000), Termination(), Unisex())
mt_r = SingleDecrementTable(collect(test_ages), q_prime_retirement, MetaData("s", "s", "s", 2000), Retirement(), Unisex())
mt_i = SingleDecrementTable(collect(test_ages), q_prime_disability, MetaData("s", "s", "s", 2000), Disability(), Unisex())

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

# 6. Teste de Flexibilidade (Construção com número reduzido de decrementos: Apenas 2 tábuas)
mdt_2dec = MultiDecrementTable(mt_d, mt_i; method = BiometricTables.UDDIndividual())

# 7. Bateria de Testes com @testset
@testset "Validação da Tábua de Múltiplos Decrementos" begin
    # 7.1. A sobrevivência total p_tau deve ser idêntica ao produto das sobrevivências independentes no ConstantForce
    p_tau_expected = (1.0 - q_prime_death[end]) * (1.0 - q_prime_turnover[end]) * (1.0 - q_prime_retirement[end]) * (1.0 - q_prime_disability[end])
    @test isapprox(px(mdt_cf, 24), p_tau_expected, atol=1e-12)
    
    # 7.2. As diferenças do q_tau total entre os métodos para taxas pequenas devem ser mínimas (ordem de 1e-5)
    @test isapprox(qx(mdt_udd, 24), qx(mdt_cf, 24), atol=1e-5)

    # 7.3. Teste do número flexível de decrementos (2 decrementos)
    @test haskey(mdt_2dec.rates, Death())
    @test haskey(mdt_2dec.rates, Disability())
    @test !haskey(mdt_2dec.rates, Termination())
    @test length(keys(mdt_2dec.rates)) == 2
    @test isapprox(qx(mdt_2dec, 24), qx(mdt_2dec, 24, Death()) + qx(mdt_2dec, 24, Disability()), atol=1e-12)
end

println("\nTodos os testes passaram com sucesso!")