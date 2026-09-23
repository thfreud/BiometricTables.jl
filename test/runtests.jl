using BiometricTables
using Test
using Aqua

#Preparar mock tábuas antes de incluir
@testset "BiometricTables.jl" begin
    @testset "Qualidade do Código (Aqua.jl)" begin
        Aqua.test_all(BiometricTables)
    end
    
    # Seus outros testes do pacote entram aqui...
end

# TODO: Preparar mock tábuas antes de incluir quaisquer outros testes.



