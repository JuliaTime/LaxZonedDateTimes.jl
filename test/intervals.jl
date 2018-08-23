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
    @testset "intersect" begin
        a = Interval(
            LaxZonedDateTime(DateTime(2013, 2, 7), winnipeg),
            LaxZonedDateTime(DateTime(2013, 2, 9, 1), winnipeg),
            false,
            true
        )

        b = Interval(
            LaxZonedDateTime(DateTime(2013, 2, 12), winnipeg),
            LaxZonedDateTime(DateTime(2013, 2, 14, 4), winnipeg),
            false,
            true
        )

        zero_lzdt = LaxZonedDateTime(DateTime(0), tz"UTC")
        @test intersect(a, b) == Interval(zero_lzdt, zero_lzdt, false, false)
    end
    @testset "astimezone" begin
        @testset "Intervals" begin
            warsaw = tz"Europe/Warsaw"
            dt = DateTime(2016, 11, 10, 1, 45)
            zdt = Interval(
                ZonedDateTime(dt - Hour(1), winnipeg),
                ZonedDateTime(dt, winnipeg),
                false,
                true
            )
            lzdt = Interval(
                LaxZonedDateTime(first(zdt)),
                LaxZonedDateTime(last(zdt)),
                false,
                true
            )

            atz_zdt = astimezone(zdt, warsaw)
            atz_lzdt = astimezone(lzdt, warsaw)
            @test atz_zdt == atz_lzdt
        end

        @testset "AnchoredIntervals" begin
            warsaw = tz"Europe/Warsaw"
            zdt = HE(ZonedDateTime(DateTime(2016, 11, 10, 1, 45), winnipeg))
            lzdt = HE(LaxZonedDateTime(DateTime(2016, 11, 10, 1, 45), winnipeg))

            atz_zdt = astimezone(zdt, warsaw)
            atz_lzdt = astimezone(lzdt, warsaw)
            @test atz_zdt == atz_lzdt
        end
    end
end
