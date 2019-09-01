module LSystem

using MacroTools

# -------------------- basic function -----------------------

"""
LModel represents a L-System model.
"""
struct LModel
    start
    rules
end

LModel(start) = LModel(Any[start], Dict())
add_rule(lmodel, left, right) = lmodel.rules[left] = right

struct LState
    model
    current_iteration
    result
end

LState(model) = LState(model, 1, model.start)
next(lstate) = expand(lstate.model, lstate) 

function expand(model, current_state)
    new_result = []
    for el in current_state.result
        next_el = get(model.rules, el, el)
        push!.(Ref(new_result), next_el)
    end
    return LState(model, current_state.current_iteration + 1, new_result)
end

function test(model::LModel, n = 2)
    state = LState(model)
    println(state.current_iteration, " => ", join(state.result))
    for i in 1:n
        state = next(state)
        println(state.current_iteration, " => ", join(state.result))
    end
end

function test_koch()
    model = LModel("F")
    add_rule(model, "F", split("F+F−F−F+F", ""))
    test(model)
end

function test_algae(n = 10)
    model = LModel("A")
    add_rule(model, "A", split("AB", ""))
    add_rule(model, "B", split("A", ""))
    test(model, n)
end

# -------------------- DSL implementation -----------------------
#= Sample usage for algae: 
    @lsys begin
        @start A
        @rule A = AB
        @rule B = A
    end
=#

# original: @start F
# expanded: model = LModel()
macro start(ex)
    if @capture(ex, v_) && v isa Symbol
        v_str = String(v)
        quote
            model = LModel($v_str)
        end
    else
        error("cannot capture ex")
        dump(ex)
    end
end

# original: @rule F = F⊕F⊖F⊖F⊕F
# expanded: add_rule(model, "F", split("F⊕F⊖F⊖F⊕F", ""))
macro rule(ex)
    if @capture(ex, v_ = w_)
        v_str = String(v)
        w_str = String(w)
        quote
            add_rule(model, $v_str, split($w_str, ""))
        end
    else
        error("cannot capture ex")
        dump(ex)
    end
end

# TODO
macro lsys(ex)
    # @capture(ex, begin 
    #     start_ 
    #     rules__ 
    # end) || error("capture error")

    # println(rmlines(start))
    # println(rmlines.(rules))

    # macroexpand(rmlines(start))
    macroexpand(@__MODULE__, ex)
end

end # module
