const GANN_HILO_PERIOD = 14

"""
    GannHilo{T}(; period=GANN_HILO_PERIOD, input_filter = always_true, input_modifier = identity, input_modifier_return_type = T)

The `GannHilo` type implements a Gann HiLo Activator indicator.
"""
mutable struct GannHilo{Tval,IN,T2} <: MovingAverageIndicator{Tval}
    value::Union{Missing,T2}
    n::Int
    output_listeners::Series
    input_indicator::Union{Missing,TechnicalIndicator}

    period::Int
    sma_high::SMA
    sma_low::SMA

    input_modifier::Function
    input_filter::Function
    input_values::CircBuff

    function GannHilo{Tval}(;
        period = GANN_HILO_PERIOD,
        input_filter = always_true,
        input_modifier = identity,
        input_modifier_return_type = Tval,
    ) where {Tval}
        T2 = input_modifier_return_type
        input_values = CircBuff(T2, period, rev = false)
        sma_high = SMA{T2}(period = period)
        sma_low = SMA{T2}(period = period)

        new{Tval,false,T2}(
            initialize_indicator_common_fields()...,
            period,
            sma_high,
            sma_low,
            input_modifier,
            input_filter,
            input_values,
        )
    end
end

function _calculate_new_value(ind::GannHilo)
    if length(ind.input_values) >= ind.period
        high = maximum(ind.input_values)
        low = minimum(ind.input_values)
        fit!(ind.sma_high, high)
        fit!(ind.sma_low, low)
        return (value(ind.sma_high), value(ind.sma_low))
    else
        return missing
    end
end