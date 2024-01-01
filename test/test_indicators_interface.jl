using IncTA:
    TechnicalIndicator,
    SISO_INDICATORS,
    SIMO_INDICATORS,
    MISO_INDICATORS,
    MIMO_INDICATORS,
    OTHERS_INDICATORS
using IncTA: always_true
using IncTA: MACDVal, macd_to_ohlcv

@testset "interfaces" begin
    files = readdir("../src/indicators")
    @test length(files) == 51  # number of indicators

    _exported = names(IncTA)

    for file in files
        stem, suffix = splitext(file)

        @testset "interface `$(stem)`" begin
            @test suffix == ".jl"  # only .jl files should be in this directory

            # each file should have a struct with the exact same name that the .jl file
            @test Symbol(stem) in _exported

            # type DataType from stem (String)
            O = eval(Meta.parse(stem))

            # OnlineStatsBase interface
            ## each indicator should have a `value` field
            hasfield(O, :value)
            ## each indicator should have a `n` field
            @test hasfield(O, :n)

            @test fieldtype(O, :n) == Int
            # TechnicalIndicator
            ## Filter/Transform : each indicator should have `input_filter` (`Function`), `input_modifier` (`Function`)
            #@test hasfield(O, :input_filter)
            @test fieldtype(O, :input_filter) == Function
            #@test hasfield(O, :input_modifier)
            @test fieldtype(O, :input_modifier) == Function
            ## Chaining : each indicator should have an `output_listeners` field (`Series`) and `input_indicator` (`Union{Missing,TechnicalIndicator}`)
            @test fieldtype(O, :output_listeners) == Series
            @test fieldtype(O, :input_indicator) == Union{Missing,TechnicalIndicator}
        end
    end
end

@testset "input filter/modifier" begin
    @testset "SISO" begin
        # SISO indicator with OHLCV input but with an input_modifier which extract close value
        for IND in SISO_INDICATORS
            @testset "$(IND)" begin
                IND = eval(Meta.parse(IND))
                ind = IND{OHLCV{Missing,Float64,Float64}}(
                    input_filter = always_true,
                    input_modifier = ValueExtractor.extract_close,
                    input_modifier_return_type = Float64,
                )
                fit!(ind, V_OHLCV)
                @test 1 == 1
            end
        end
    end
    @testset "SIMO" begin
        # SIMO indicator with OHLCV input but with an input_modifier which extract close value
        for IND in SIMO_INDICATORS
            @testset "$(IND)" begin
                IND = eval(Meta.parse(IND))
                ind = IND{OHLCV{Missing,Float64,Float64}}(
                    input_filter = always_true,
                    input_modifier = ValueExtractor.extract_close,
                    input_modifier_return_type = Float64,
                )
                fit!(ind, V_OHLCV)
                @test 1 == 1
            end
        end
    end
    @testset "MISO" begin
        # MISO indicator with MACDVal input but with an input_modifier which return OHLCV from MACDVal
        for IND in MISO_INDICATORS
            @testset "$(IND)" begin
                IND = eval(Meta.parse(IND))
                ind = IND{MACDVal,Float64}(
                    input_filter = always_true,
                    input_modifier = macd_to_ohlcv,
                    input_modifier_return_type = OHLCV,
                )
                fit!(ind, MACDVal(0.0, 0.0, 0.0))
                @test 1 == 1
            end
        end
    end

    @testset "MIMO" begin
        # MIMO indicator with MACDVal input but with an input_modifier which return OHLCV from MACDVal
        for IND in MIMO_INDICATORS
            @testset "$(IND)" begin
                IND = eval(Meta.parse(IND))
                ind = IND{MACDVal,Float64}(
                    input_filter = always_true,
                    input_modifier = macd_to_ohlcv,
                    input_modifier_return_type = OHLCV,
                )
                fit!(ind, MACDVal(0.0, 0.0, 0.0))
                @test 1 == 1
            end
        end
    end

    @testset "Others" begin
        # others indicators (ie more complex indicators which are of one category SISO, SIMO, MISO, MIMO but are using indicators of an other one category)
        @testset "STC" begin
            ind = STC{OHLCV}(
                input_filter = always_true,
                input_modifier = ValueExtractor.extract_close,
                input_modifier_return_type = Float64,
            )
            fit!(ind, OHLCV(0.0, 0.0, 0.0, 0.0, volume = 0.0))
        end
    end

end