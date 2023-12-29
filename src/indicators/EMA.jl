const EMA_PERIOD = 3


"""
    EMA{T}(; period=EMA_PERIOD)

The `EMA` type implements an Exponential Moving Average indicator.
"""
mutable struct EMA{Tval} <: MovingAverageIndicator{Tval}
    value::Union{Missing,Tval}
    n::Int

    period::Int

    rolling::Bool
    input_values::CircBuff{Tval}

    function EMA{Tval}(; period = EMA_PERIOD) where {Tval}
        input = CircBuff(Tval, period, rev = false)
        new{Tval}(missing, 0, period, false, input)
    end
end

function OnlineStatsBase._fit!(ind::EMA, val)
    fit!(ind.input_values, val)
    if ind.rolling  # CircBuff is full and rolling
        mult = 2.0 / (ind.period + 1.0)
        ind.value = mult * ind.input_values[end] + (1.0 - mult) * ind.value
    else
        if ind.n + 1 == ind.period # CircBuff is full but not rolling
            ind.rolling = true
            ind.n += 1
            ind.value = sum(ind.input_values.value) / ind.period
        else  # CircBuff is filling up
            ind.n += 1
            ind.value = missing
        end
    end
end
