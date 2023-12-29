const ForceIndex_PERIOD = 3

"""
    ForceIndex{Tohlcv,S}(; period = ForceIndex_PERIOD, ma = EMA)

The `ForceIndex` type implements a Force Index indicator.
"""
mutable struct ForceIndex{Tohlcv,S} <: TechnicalIndicator{Tohlcv}
    value::Union{Missing,S}
    n::Int

    period::Integer

    ma::MovingAverageIndicator  # EMA

    input_values::Tuple{Union{Missing,Tohlcv},Union{Missing,Tohlcv}}

    function ForceIndex{Tohlcv,S}(; period = ForceIndex_PERIOD, ma = EMA) where {Tohlcv,S}
        _ma = MAFactory(S)(ma, period)
        input = (missing, missing)
        new{Tohlcv,S}(missing, 0, period, _ma, input)
    end
end

function OnlineStatsBase._fit!(ind::ForceIndex, candle::OHLCV)
    ind.input_values = (ind.input_values[end], candle)  # Keep a small window of input values
    ind.n += 1
    if ind.n >= 2
        fit!(
            ind.ma,
            (ind.input_values[end].close - ind.input_values[end-1].close) * ind.input_values[end].volume,
        )
        if has_output_value(ind.ma)
            ind.value = value(ind.ma)
        else
            ind.value = missing
        end
    else
        ind.value = missing
    end
end
