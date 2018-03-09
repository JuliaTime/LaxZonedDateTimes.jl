using Intervals

@testset "AnchoredIntervals" begin
    @testset "ranges" begin
        # basic
        s = LaxZonedDateTime(DateTime(2016, 3, 14, 3, 45), winnipeg)
        f = LaxZonedDateTime(DateTime(2016, 3, 18, 3, 45), winnipeg)
        @test HourEnding(s):HourEnding(f) == HourEnding(s):Hour(1):HourEnding(f)

        r = HourEnding(s):Day(2):HourEnding(f)
        @test isa(r, StepRange{HourEnding{LaxZonedDateTime}, Day})
        @test collect(r) == [
            HourEnding(LaxZonedDateTime(DateTime(2016, 3, 14, 3, 45), winnipeg)),
            HourEnding(LaxZonedDateTime(DateTime(2016, 3, 16, 3, 45), winnipeg)),
            HourEnding(LaxZonedDateTime(DateTime(2016, 3, 18, 3, 45), winnipeg)),
        ]

        r = HourEnding(f):Day(-2):HourEnding(s)
        @test isa(r, StepRange{HourEnding{LaxZonedDateTime}, Day})
        @test collect(r) == [
            HourEnding(LaxZonedDateTime(DateTime(2016, 3, 18, 3, 45), winnipeg)),
            HourEnding(LaxZonedDateTime(DateTime(2016, 3, 16, 3, 45), winnipeg)),
            HourEnding(LaxZonedDateTime(DateTime(2016, 3, 14, 3, 45), winnipeg)),
        ]

        # step past AMB
        s = LaxZonedDateTime(DateTime(2016, 11, 4, 1, 45), winnipeg)
        f = LaxZonedDateTime(DateTime(2016, 11, 8, 1, 45), winnipeg)

        r = HourEnding(s):Day(2):HourEnding(f)
        @test isa(r, StepRange{HourEnding{LaxZonedDateTime}, Day})
        @test collect(r) == [
            HourEnding(LaxZonedDateTime(DateTime(2016, 11, 4, 1, 45), winnipeg)),
            HourEnding(LaxZonedDateTime(DateTime(2016, 11, 6, 1, 45), winnipeg)),   # AMB
            HourEnding(LaxZonedDateTime(DateTime(2016, 11, 8, 1, 45), winnipeg)),
        ]

        r = HourEnding(f):Day(-2):HourEnding(s)
        @test isa(r, StepRange{HourEnding{LaxZonedDateTime}, Day})
        @test collect(r) == [
            HourEnding(LaxZonedDateTime(DateTime(2016, 11, 8, 1, 45), winnipeg)),
            HourEnding(LaxZonedDateTime(DateTime(2016, 11, 6, 1, 45), winnipeg)),   # AMB
            HourEnding(LaxZonedDateTime(DateTime(2016, 11, 4, 1, 45), winnipeg)),
        ]

        # start/finish is AMB
        s = LaxZonedDateTime(DateTime(2016, 11, 2, 1, 45), winnipeg)
        f = LaxZonedDateTime(DateTime(2016, 11, 6, 1, 45), winnipeg)

        r = HourEnding(s):Day(2):HourEnding(f)
        @test isa(r, StepRange{HourEnding{LaxZonedDateTime}, Day})
        @test collect(r) == [
            HourEnding(LaxZonedDateTime(DateTime(2016, 11, 2, 1, 45), winnipeg)),
            HourEnding(LaxZonedDateTime(DateTime(2016, 11, 4, 1, 45), winnipeg)),
            HourEnding(LaxZonedDateTime(DateTime(2016, 11, 6, 1, 45), winnipeg)),   # AMB
        ]

        r = HourEnding(f):Day(-2):HourEnding(s)
        @test isa(r, StepRange{HourEnding{LaxZonedDateTime}, Day})
        @test collect(r) == [
            HourEnding(LaxZonedDateTime(DateTime(2016, 11, 6, 1, 45), winnipeg)),   # AMB
            HourEnding(LaxZonedDateTime(DateTime(2016, 11, 4, 1, 45), winnipeg)),
            HourEnding(LaxZonedDateTime(DateTime(2016, 11, 2, 1, 45), winnipeg)),
        ]

        s = LaxZonedDateTime(DateTime(2016, 11, 6, 1, 45), winnipeg)
        f = LaxZonedDateTime(DateTime(2016, 11, 10, 1, 45), winnipeg)

        r = HourEnding(s):Day(2):HourEnding(f)
        @test isa(r, StepRange{HourEnding{LaxZonedDateTime}, Day})
        @test collect(r) == [
            HourEnding(LaxZonedDateTime(DateTime(2016, 11, 6, 1, 45), winnipeg)),   # AMB
            HourEnding(LaxZonedDateTime(DateTime(2016, 11, 8, 1, 45), winnipeg)),
            HourEnding(LaxZonedDateTime(DateTime(2016, 11, 10, 1, 45), winnipeg)),
        ]

        r = HourEnding(f):Day(-2):HourEnding(s)
        @test isa(r, StepRange{HourEnding{LaxZonedDateTime}, Day})
        @test collect(r) == [
            HourEnding(LaxZonedDateTime(DateTime(2016, 11, 10, 1, 45), winnipeg)),
            HourEnding(LaxZonedDateTime(DateTime(2016, 11, 8, 1, 45), winnipeg)),
            HourEnding(LaxZonedDateTime(DateTime(2016, 11, 6, 1, 45), winnipeg)),   # AMB
        ]
    end
end
