module LSystem

export LState, next, result
export @lsys, @axiom, @rule

using MacroTools

# -------------------- basic function -----------------------

"""
A L-system model is represented by an axiom called `axiom`
and a set of rewriting `rules`.
"""
struct LModel
    axiom
    rules
end

"Create a L-system model."
LModel(axiom) = LModel(Any[axiom], Dict())

"Add rule to a model."
add_rule(lmodel, left, right) = lmodel.rules[left] = right

"""
A L-system state contains a reference to the `model`, the 
current iteration, and the result.
"""
struct LState
    model
    current_iteration
    result
end

"Create a L-system state from a `model`."
LState(model) = LState(model, 1, model.axiom)

"Advance to the next state and returns a new LState object."
next(lstate) = expand(lstate.model, lstate) 

"Current result"
result(lstate) = join(lstate.result)

"Repeated next call"
next(lstate, n) = n > 0 ? next(next(lstate), n-1) : lstate

Base.show(io::IO, s::LState) = 
    print(io, "LState(", s.current_iteration, "): ", result(s))

"""
Expand the current result to a new result by applying the 
rewriting rules in the model.
"""
function expand(model, current_state)
    new_result = []
    for el in current_state.result
        next_el = get(model.rules, el, el)
        push!.(Ref(new_result), next_el)
    end
    return LState(model, current_state.current_iteration + 1, new_result)
end

# -------------------- DSL implementation -----------------------
#= Sample usage for algae: 
    @lsys begin
        @axiom A
        @rule A → AB
        @rule B → A
    end
=#

# Define syntax for the transformation operator (arrow)
→(a, b) = (a, b)

# original: @axiom F
# expanded: model = LModel()
macro axiom(ex)
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
    if @capture(ex, v_ → w_)
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

# Model DSL
macro lsys(ex)
    ret = macroexpand(@__MODULE__, ex)

    # Convert model symbol e.g. ##10#model -> model_1
    ret = MacroTools.gensym_ids(ret)

    # Replace first argument to the add_rule function with model_1 
    ret = MacroTools.postwalk(
        x -> @capture(x, f_(m_, left_, right_)) ?
                :( LSystem.add_rule(model_1, $(left), $(right)) ) : x, ret)

    # Make model_1 as the last expression of the block
    ret = quote
        $ret
        model_1
    end

    # Flatten the code structure 
    ret = MacroTools.flatten(ret)

    # -- uncomment this line to debug --
    # MacroTools.postwalk(rmlines, ret) |> println

    return ret
end

end # module
