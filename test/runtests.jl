using LSystem
using Test
using Lazy

using LSystem: LModel, LState, next, result

@testset "LSystem.jl" begin

function generate(model::LModel, n::Integer)
    state = LState(model)
    println(state.current_iteration, " => ", join(state.result))
    for i in 1:n
        state = next(state)
        println(state.current_iteration, " => ", join(state.result))
    end
end

# Algae

algae_model = @lsys begin
    axiom : A
    rule  : A → AB
    rule  : B → A
end

@test (@> algae_model LState next(0) result) == "A"
@test (@> algae_model LState next(1) result) == "AB"
@test (@> algae_model LState next(2) result) == "ABA"
@test (@> algae_model LState next(3) result) == "ABAAB"

end
