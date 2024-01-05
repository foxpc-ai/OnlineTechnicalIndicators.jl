module IncTA

export OHLCV, OHLCVFactory, ValueExtractor
export fit!

export SampleData
export ArraysInterface

SISO_INDICATORS = [
    "SMA",
    "EMA",
    "SMMA",
    "RSI",
    "MeanDev",
    "StdDev",
    "ROC",
    "WMA",
    "KAMA",
    "HMA",
    "DPO",
    "CoppockCurve",
    "DEMA",
    "TEMA",
    "ALMA",
    "McGinleyDynamic",
    "ZLEMA",
    "T3",
    "TRIX",
    "TSI",
]
SIMO_INDICATORS = ["BB", "MACD", "StochRSI", "KST"]
MISO_INDICATORS = [
    "AccuDist",
    "BOP",
    "CCI",
    "ChaikinOsc",
    "VWMA",
    "VWAP",
    "AO",
    "ATR",
    "ForceIndex",
    "OBV",
    "SOBV",
    "EMV",
    "MassIndex",
    "CHOP",
    "KVO",
    "UO",
]
MIMO_INDICATORS = [
    "Stoch",
    "ADX",
    "SuperTrend",
    "VTX",
    "DonchianChannels",
    "KeltnerChannels",
    "Aroon",
    "ChandeKrollStop",
    "ParabolicSAR",
    "SFX",
    "TTM",
    "PivotsHL",
]
# More complex indicators (for example STC is SISO but uses MIMO indicator such as Stoch with input_modifier)
OTHERS_INDICATORS = ["STC"]

# Export indicators
for ind in [
    SISO_INDICATORS...,
    SIMO_INDICATORS...,
    MISO_INDICATORS...,
    MIMO_INDICATORS...,
    OTHERS_INDICATORS...,
]
    ind = Symbol(ind)
    @eval export $ind
end
export SARTrend, Trend, HLType

export add_input_indicator!

using OnlineStatsBase
export value

abstract type TechnicalIndicator{T} <: OnlineStat{T} end
abstract type TechnicalIndicatorSingleOutput{T} <: TechnicalIndicator{T} end
abstract type TechnicalIndicatorMultiOutput{T} <: TechnicalIndicator{T} end
abstract type MovingAverageIndicator{T} <: TechnicalIndicatorSingleOutput{T} end

include("ohlcv.jl")
include("sample_data.jl")

function initialize_indicator_common_fields()
    value = missing
    n = 0
    output_listeners = Series()
    input_indicator = missing
    return value, n, output_listeners, input_indicator
end

ismultiinput(ind::O) where {O<:TechnicalIndicator} = typeof(ind).parameters[2]
# ismultioutput(ind::O) where {O<:TechnicalIndicator} = typeof(ind).parameters[3]  # to implement
expected_return_type(ind::O) where {O<:TechnicalIndicatorSingleOutput} =
    typeof(ind).parameters[end]
function expected_return_type(ind::O) where {O<:TechnicalIndicatorMultiOutput}
    retval = String(nameof(typeof(ind))) * "Val"  # return value as String "BBVal", "MACDVal"...
    RETVAL = eval(Meta.parse(retval))
    return RETVAL{typeof(ind).parameters[end]}
end

function OnlineStatsBase._fit!(ind::O, data) where {O<:TechnicalIndicator}
    _fieldnames = fieldnames(O)
    #if :input_filter in _fieldnames && :input_modifier in _fieldnames  # input_filter/input_modifier is like FilterTransform
    if ind.input_filter(data)
        data = ind.input_modifier(data)
    else
        return nothing
    end
    #end
    has_input_values = :input_values in _fieldnames
    if has_input_values
        fit!(ind.input_values, data)
    end
    has_sub_indicators =
        :sub_indicators in _fieldnames && length(ind.sub_indicators.stats) > 0
    if has_sub_indicators
        fit!(ind.sub_indicators, data)
    end
    ind.n += 1
    ind.value =
        (has_input_values || has_sub_indicators) ? _calculate_new_value(ind) :
        _calculate_new_value_only_from_incoming_data(ind, data)
    fit_listeners!(ind)
end

is_valid(::Missing) = false

function has_output_value(ind::O) where {O<:OnlineStat}
    return !ismissing(value(ind))
end


function has_output_value(cb::CircBuff)
    if length(cb.value) > 0
        return !ismissing(cb[end])
    else
        return false
    end
end

#=
function has_valid_values(cb::CircBuff, period)
    try
        _has_valid_values = true
        for i in 1:period
            _has_valid_values = _has_valid_values && !ismissing(cb[end-i+1])
        end
        return _has_valid_values
    catch
        return false
    end
end
=#

function has_valid_values(sequence::CircBuff, window; exact = false)
    if !exact
        return length(sequence) >= window && !ismissing(sequence[end-window+1])
    else
        return (length(sequence) == window && !ismissing(sequence[end-window+1])) || (
            length(sequence) > window &&
            !ismissing(sequence[end-window+1]) &&
            ismissing(sequence[end-window])
        )
    end
end

function fit_listeners!(ind::O) where {O<:TechnicalIndicator}
    if :output_listeners in fieldnames(typeof(ind))
        if length(ind.output_listeners.stats) == 0
            return
        end
        for listener in ind.output_listeners.stats
            if listener.input_filter(ind.value)
                fit!(listener, ind.value)
            end
        end
    end
end

function add_input_indicator!(
    ind2::O1,
    ind1::O2,
) where {O1<:TechnicalIndicator,O2<:TechnicalIndicator}
    ind2.input_indicator = ind1
    if length(ind1.output_listeners.stats) > 0
        ind1.output_listeners = merge(ind1.output_listeners, ind2)
    else
        ind1.output_listeners = Series(ind2)
    end
end

always_true(x) = true

function Base.setindex!(o::CircBuff, val, i::Int)
    if nobs(o) ≤ length(o.rng.rng)
        o.value[i] = val
    else
        o.value[o.rng[nobs(o)+i]] = val
    end
end
function Base.setindex!(o::CircBuff{<:Any,true}, val, i::Int)
    i = length(o.value) - i + 1
    if nobs(o) ≤ length(o.rng.rng)
        o.value[i] = val
    else
        o.value[o.rng[nobs(o)+i]] = val
    end
end

# include SISO, SIMO, MISO, MIMO and OTHERS indicators
for ind in [
    SISO_INDICATORS...,
    SIMO_INDICATORS...,
    MISO_INDICATORS...,
    MIMO_INDICATORS...,
    OTHERS_INDICATORS...,
]
    include("indicators/$(ind).jl")
end

# Other stuff
include("ma.jl")  # Moving Average Factory

# Integration with Julia ecosystem (Arrays, Iterators...)
include("other/arrays.jl")
include("other/iterators.jl")
include("other/tables.jl")

end
