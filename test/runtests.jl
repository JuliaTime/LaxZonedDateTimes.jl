using LaxZonedDateTimes
using Base.Test
using TimeZones
using TimeZones: Transition, timezone, utc
using Base.Dates: Year, Month, Week, Day, Hour, Minute, Second, Millisecond
using LaxZonedDateTimes: NonExistent, isrepresentable

const winnipeg = TimeZone("America/Winnipeg")

@testset "LaxZonedDateTimes" begin
    t = VariableTimeZone("Testing", [
        Transition(DateTime(1800,1,1), FixedTimeZone("TST",0,0)),
        Transition(DateTime(1960,4,1,2), FixedTimeZone("TDT",0,7200)),   # 1960-04-01 02:00
        Transition(DateTime(1960,4,1,3), FixedTimeZone("TET",0,10800)),  # 1960-04-01 05:00
        Transition(DateTime(1960,4,1,10), FixedTimeZone("TDT",0,7200)),  # 1960-04-02 12:00
    ])


    @test LaxZonedDateTime(DateTime(1960,3,31,3), t) + Day(1) == LaxZonedDateTime(DateTime(1960,4,1,3), t, NonExistent())

    valid_a = LaxZonedDateTime(DateTime(1960,4,1,1), t)
    valid_b = LaxZonedDateTime(DateTime(1960,4,1,6), t)
    non_existent_a = LaxZonedDateTime(DateTime(1960,4,1,2), t, NonExistent())
    non_existent_b = LaxZonedDateTime(DateTime(1960,4,1,3), t, NonExistent())

    null = LaxZonedDateTime()
    @test valid_a + Hour(2) == valid_b
    @test isequal(non_existent_a + Hour(1), null)
    @test isequal(non_existent_b + Hour(1), null)

    ambiguous = LaxZonedDateTime(DateTime(1960,4,1,12),t)

    @test isequal(non_existent_a + Hour(0), null)
    @test isequal(non_existent_b + Hour(0), null)
    @test isequal(ambiguous + Hour(0), null)

    @test isequal(ambiguous - Hour(1), null)
    @test isequal(ambiguous + Hour(1), null)


    lzdt = LaxZonedDateTime(ZonedDateTime(2015,3,7,2, winnipeg))
    lzdt += Day(1)
    @test lzdt == LaxZonedDateTime(DateTime(2015,3,8,2), winnipeg, NonExistent())
    lzdt += Day(1)
    @test lzdt == LaxZonedDateTime(ZonedDateTime(2015,3,9,2,winnipeg))

    non_existent = LaxZonedDateTime(DateTime(2015,3,8,2), winnipeg, NonExistent())
    @test isequal(non_existent + Hour(1), LaxZonedDateTime())
    @test isequal(non_existent - Hour(1), LaxZonedDateTime())
    @test isequal(non_existent + Hour(0), LaxZonedDateTime())
    @test isequal(non_existent - Hour(0), LaxZonedDateTime())

    @test isequal((non_existent + Hour(1)) + Hour(1), LaxZonedDateTime())
    @test isequal((non_existent + Hour(1)) + Day(1), LaxZonedDateTime())

    #=
    using Base.Dates
    using TimeZones

    r = ZonedDateTime(2015,3,9,1,winnipeg):Hour(1):ZonedDateTime(2015,3,10,winnipeg)
    a = collect(r)

    l = map(LaxZonedDateTime, a)
    l - Day(1)
    =#

    @test LaxZonedDateTime(ZonedDateTime(2014,winnipeg)) < ZonedDateTime(2015,winnipeg)

    amb = LaxZonedDateTime(DateTime(2015,11,1,1),winnipeg)
    amb_first = LaxZonedDateTime(ZonedDateTime(2015,11,1,1,winnipeg,1))
    amb_last = LaxZonedDateTime(ZonedDateTime(2015,11,1,1,winnipeg,2))

    @test amb_first < amb_last
    @test !(amb_first < amb)
    @test !(amb < amb_first)
    @test !(amb_last < amb)
    @test !(amb < amb_last)

    non_existent = LaxZonedDateTime(DateTime(2015,3,8,2),winnipeg)
    @test ZonedDateTime(2015,3,8,1,winnipeg) < non_existent < ZonedDateTime(2015,3,8,3,winnipeg)


    @test hour(amb) == hour(amb_first) == hour(amb_last) == 1
    @test hour(non_existent) == 2

    @test month(amb) == 11

    @test_throws Exception localtime(null)
    @test_throws Exception utc(null)
    @test_throws Exception hour(null)


    a = ZonedDateTime(2016, 11, 6, 1, 30, winnipeg, 1)
    b = ZonedDateTime(2016, 11, 6, 1, winnipeg, 2)

    @test LaxZonedDateTime(a) < b


    @test !isambiguous(null)
    @test isambiguous(amb)
    @test !isambiguous(amb_first)
    @test !isambiguous(amb_last)
    @test !isambiguous(non_existent)

    @test !isnonexistent(null)
    @test !isnonexistent(amb)
    @test !isnonexistent(amb_first)
    @test !isnonexistent(amb_last)
    @test isnonexistent(non_existent)

    @test get(amb_last - amb_first) == Dates.Hour(1)
    @test isnull(amb - amb_first)
    @test isnull(non_existent - amb_first)
    @test isnull(null - amb_first)


    @testset "FixedTimeZone" begin
        utc = TimeZone("UTC")
        fixed = FixedTimeZone("UTC-06:00")
        dt = DateTime(2016, 8, 11, 2, 30)

        for t in (utc, fixed)
            @test ZonedDateTime(LaxZonedDateTime(dt, t)) == ZonedDateTime(dt, t)
            for p in (Hour(1), Day(1))
                @test LaxZonedDateTime(dt, t) + p == LaxZonedDateTime(dt + p, t)
                @test LaxZonedDateTime(dt, t) - p == LaxZonedDateTime(dt - p, t)
            end
        end
    end

    @testset "null equality" begin
        # Unrepresentable LZDTs are treated like NaNs
        null = LaxZonedDateTime()
        @test null != null
        @test isequal(null, null)

        # Test that unrepresentable LZDTs initialized with different values hash the same
        utc = TimeZone("UTC")
        null_2 = LaxZonedDateTime(DateTime(2013, 2, 13, 0, 30), utc, utc, false)
        @test isequal(null, null_2)
        @test hash(null) == hash(null_2)
    end

    @testset "astimezone" begin
        warsaw = tz"Europe/Warsaw"
        zdt = ZonedDateTime(DateTime(2016, 11, 10, 1, 45), winnipeg)
        lzdt = LaxZonedDateTime(DateTime(2016, 11, 10, 1, 45), winnipeg)
        dne = LaxZonedDateTime(DateTime(2015, 3, 8, 2), winnipeg)
        amb1 = LaxZonedDateTime(DateTime(2016, 11, 6, 1, 45), winnipeg)


        atz_zdt = astimezone(zdt, warsaw)
        atz_lzdt = astimezone(lzdt, warsaw)
        @test atz_zdt == atz_lzdt
        @test timezone(atz_zdt) == timezone(atz_lzdt)
        @test utc(lzdt) == utc(atz_lzdt)

        atz_dne = astimezone(dne, warsaw)
        atz_amb = astimezone(amb, warsaw)
        @test timezone(atz_dne) != warsaw
        @test timezone(atz_amb) != warsaw
        @test !isvalid(atz_dne)
        @test !isvalid(atz_amb)
    end

    @testset "rounding" begin
        st_johns = TimeZone("America/St_Johns")     # UTC-3:30 (or UTC-2:30)
        eucla = TimeZone("Australia/Eucla")         # UTC+8:45
        colombo = TimeZone("Asia/Colombo")          # See note below

        #=
        On 1996-05-25 at 00:00, the Asia/Colombo time zone in Sri Lanka moved from Indian
        Standard Time (UTC+5:30) to Lanka Time (UTC+6:30). On 1996-10-26 at 00:30, Lanka
        Time was revised from UTC+6:30 to UTC+6:00, marking a -00:30 transition. Transitions
        like these are doubly unusual (compared to the more common DST transitions) as it is both
        an half-hour transition and a transition that lands at midnight (causing
        1996-10-26T00:00 to be ambiguous; midnights are rarely ambiguous). In 2006,
        Asia/Colombo returned to Indian Standard Time, causing another -00:30 transition
        from 00:30 to 00:00.
        =#

        @testset "basic" begin
            dt = DateTime(2016, 2, 5, 13, 10, 20, 500)
            for tz in [winnipeg, st_johns, eucla, colombo]
                lzdt = LaxZonedDateTime(dt, tz)

                @test floor(lzdt, Year) == LaxZonedDateTime(DateTime(2016), tz)
                @test floor(lzdt, Month) == LaxZonedDateTime(DateTime(2016, 2), tz)
                @test floor(lzdt, Week) == LaxZonedDateTime(DateTime(2016, 2), tz)
                @test floor(lzdt, Day) == LaxZonedDateTime(DateTime(2016, 2, 5), tz)
                @test floor(lzdt, Hour) == LaxZonedDateTime(DateTime(2016, 2, 5, 13), tz)
                @test floor(lzdt, Minute) == LaxZonedDateTime(DateTime(2016, 2, 5, 13, 10), tz)
                @test floor(lzdt, Second) == LaxZonedDateTime(DateTime(2016, 2, 5, 13, 10, 20), tz)

                @test ceil(lzdt, Year) == LaxZonedDateTime(DateTime(2017), tz)
                @test ceil(lzdt, Month) == LaxZonedDateTime(DateTime(2016, 3), tz)
                @test ceil(lzdt, Week) == LaxZonedDateTime(DateTime(2016, 2, 8), tz)
                @test ceil(lzdt, Day) == LaxZonedDateTime(DateTime(2016, 2, 6), tz)
                @test ceil(lzdt, Hour) == LaxZonedDateTime(DateTime(2016, 2, 5, 14), tz)
                @test ceil(lzdt, Minute) == LaxZonedDateTime(DateTime(2016, 2, 5, 13, 11), tz)
                @test ceil(lzdt, Second) == LaxZonedDateTime(DateTime(2016, 2, 5, 13, 10, 21), tz)

                @test round(lzdt, Year) == LaxZonedDateTime(DateTime(2016), tz)
                @test round(lzdt, Month) == LaxZonedDateTime(DateTime(2016, 2), tz)
                @test round(lzdt, Week) == LaxZonedDateTime(DateTime(2016, 2, 8), tz)
                @test round(lzdt, Day) == LaxZonedDateTime(DateTime(2016, 2, 6), tz)
                @test round(lzdt, Hour) == LaxZonedDateTime(DateTime(2016, 2, 5, 13), tz)
                @test round(lzdt, Minute) == LaxZonedDateTime(DateTime(2016, 2, 5, 13, 10), tz)
                @test round(lzdt, Second) == LaxZonedDateTime(DateTime(2016, 2, 5, 13, 10, 21), tz)
            end
        end

        @testset "transition" begin
            lzdt = LaxZonedDateTime(DateTime(2016, 3, 13, 1, 45), winnipeg)
            @test floor(lzdt, Day) == LaxZonedDateTime(DateTime(2016, 3, 13), winnipeg)
            @test floor(lzdt, Hour) == LaxZonedDateTime(DateTime(2016, 3, 13, 1), winnipeg)
            @test ceil(lzdt, Day) == LaxZonedDateTime(DateTime(2016, 3, 14), winnipeg)
            @test ceil(lzdt, Hour) == LaxZonedDateTime(DateTime(2016, 3, 13, 3), winnipeg)
            @test round(lzdt, Day) == LaxZonedDateTime(DateTime(2016, 3, 13), winnipeg)
            @test round(lzdt, Hour) == LaxZonedDateTime(DateTime(2016, 3, 13, 3), winnipeg)

            lzdt = LaxZonedDateTime(DateTime(1996, 10, 26, 0, 45), colombo)
            @test floor(lzdt, Hour) == LaxZonedDateTime(ZonedDateTime(1996, 10, 26, colombo, 2))
            @test isambiguous(floor(lzdt, Day))

            lzdt = LaxZonedDateTime(DateTime(1996, 10, 25, 23, 45), colombo)
            @test ceil(lzdt, Hour) == LaxZonedDateTime(ZonedDateTime(1996, 10, 26, colombo, 1))
            @test isambiguous(ceil(lzdt, Day))

            # Using `round` when either `ceil` or `floor` would result in an ambiguous or
            # missing date results in something unrepresentable (because `round` can't
            # figure out whether to use the result from `floor` or `ceil`).
            lzdt = LaxZonedDateTime(DateTime(1996, 10, 25, 23, 45), colombo)
            @test round(lzdt, Hour) == LaxZonedDateTime(ZonedDateTime(1996, 10, 26, colombo, 1))
            @test !isrepresentable(round(lzdt, Day))

            # Rounding ambiguous or missing dates to a `TimePeriod` results in
            # unrepresentable values.
            lzdt = LaxZonedDateTime(DateTime(2016, 3, 13, 2, 45), winnipeg)
            @test !isvalid(lzdt)
            @test !isambiguous(lzdt)
            @test isnonexistent(lzdt)
            @test isrepresentable(lzdt)

            for p in [Year, Month, Week, Day]
                for r in [floor, ceil, round]
                    @test isrepresentable(r(lzdt, p))
                end
            end

            for p in [Hour, Minute, Second]
                for r in [floor, ceil, round]
                    @test !isrepresentable(r(lzdt, p))
                end
            end

            lzdt = LaxZonedDateTime(DateTime(2015, 11, 1, 1, 15), winnipeg)
            @test !isvalid(lzdt)
            @test isambiguous(lzdt)
            @test !isnonexistent(lzdt)
            @test isrepresentable(lzdt)

            for p in [Year, Month, Week, Day]
                for r in [floor, ceil, round]
                    @test isrepresentable(r(lzdt, p))
                end
            end

            for p in [Hour, Minute, Second]
                for r in [floor, ceil, round]
                    @test !isrepresentable(r(lzdt, p))
                end
            end
        end
    end

    @testset "ranges" begin
        #=
        If start and/or finish is unrepresentable, the range collects to nothing.
        If start is AMB/DNE, and step is a DatePeriod, it works (start still DNE/AMB)
        If start is AMB/DNE, and step is a TimePeriod, the range collects to nothing.
        If finish is AMB/DNE, and step is a DatePeriod, it works (last element may be
            DNE/AMB)
        If finish is AMB/DNE, and step is a TimePeriod, it works (last element omitted for
            DNE, both specific versions included for AMB)

        When transitions occur between the start and end of a range, they are skipped over
        as per the TimeZones.jl implementation (e.g., when stepping one hour at a time, a
        "spring forward" will result in the range collecting to 0:00, 1:00, 3:00, ...). A
        DNE LaxZonedDateTime will only appear in cases where TimeZones.jl would throw an
        error (e.g., stepping through the "spring forward" transition one day at a time, and
        landing on the missing hour).
        =#

        @testset "basic" begin
            # Default step
            start = LaxZonedDateTime(DateTime(2016, 3, 13, 3, 45), winnipeg)
            finish = LaxZonedDateTime(DateTime(2016, 3, 13, 8, 45), winnipeg)
            @test start:finish == start:Millisecond(1):finish

            # Positive step
            r = start:Hour(1):finish
            @test isa(r, StepRange{LaxZonedDateTime, Hour})
            @test collect(r) == [
                LaxZonedDateTime(DateTime(2016, 3, 13, 3, 45), winnipeg),
                LaxZonedDateTime(DateTime(2016, 3, 13, 4, 45), winnipeg),
                LaxZonedDateTime(DateTime(2016, 3, 13, 5, 45), winnipeg),
                LaxZonedDateTime(DateTime(2016, 3, 13, 6, 45), winnipeg),
                LaxZonedDateTime(DateTime(2016, 3, 13, 7, 45), winnipeg),
                LaxZonedDateTime(DateTime(2016, 3, 13, 8, 45), winnipeg)
            ]

            finish = LaxZonedDateTime(DateTime(2016, 3, 18, 3, 45), winnipeg)
            r = start:Day(2):finish
            @test isa(r, StepRange{LaxZonedDateTime, Day})
            @test collect(r) == [
                LaxZonedDateTime(DateTime(2016, 3, 13, 3, 45), winnipeg),
                LaxZonedDateTime(DateTime(2016, 3, 15, 3, 45), winnipeg),
                LaxZonedDateTime(DateTime(2016, 3, 17, 3, 45), winnipeg)
            ]

            # Negative step
            start = LaxZonedDateTime(DateTime(2016, 3, 13, 8, 45), winnipeg)
            finish = LaxZonedDateTime(DateTime(2016, 3, 13, 3, 45), winnipeg)
            r = start:Hour(-1):finish
            @test isa(r, StepRange{LaxZonedDateTime, Hour})
            @test collect(r) == [
                LaxZonedDateTime(DateTime(2016, 3, 13, 8, 45), winnipeg),
                LaxZonedDateTime(DateTime(2016, 3, 13, 7, 45), winnipeg),
                LaxZonedDateTime(DateTime(2016, 3, 13, 6, 45), winnipeg),
                LaxZonedDateTime(DateTime(2016, 3, 13, 5, 45), winnipeg),
                LaxZonedDateTime(DateTime(2016, 3, 13, 4, 45), winnipeg),
                LaxZonedDateTime(DateTime(2016, 3, 13, 3, 45), winnipeg)
            ]

            start = LaxZonedDateTime(DateTime(2016, 3, 18, 3, 45), winnipeg)
            r = start:Day(-2):finish
            @test isa(r, StepRange{LaxZonedDateTime, Day})
            @test collect(r) == [
                LaxZonedDateTime(DateTime(2016, 3, 18, 3, 45), winnipeg),
                LaxZonedDateTime(DateTime(2016, 3, 16, 3, 45), winnipeg),
                LaxZonedDateTime(DateTime(2016, 3, 14, 3, 45), winnipeg)
            ]
        end

        @testset "step through transition" begin
            # step past DNE (hourly)
            start = LaxZonedDateTime(DateTime(2016, 3, 13, 0, 45), winnipeg)
            finish = LaxZonedDateTime(DateTime(2016, 3, 13, 5, 45), winnipeg)
            r = start:Hour(1):finish
            @test isa(r, StepRange{LaxZonedDateTime, Hour})
            @test collect(r) == [
                LaxZonedDateTime(DateTime(2016, 3, 13, 0, 45), winnipeg),
                LaxZonedDateTime(DateTime(2016, 3, 13, 1, 45), winnipeg),
                LaxZonedDateTime(DateTime(2016, 3, 13, 3, 45), winnipeg),   # Skip DNE
                LaxZonedDateTime(DateTime(2016, 3, 13, 4, 45), winnipeg),
                LaxZonedDateTime(DateTime(2016, 3, 13, 5, 45), winnipeg)
            ]

            # step past DNE (hourly, backward)
            r = finish:Hour(-1):start
            @test isa(r, StepRange{LaxZonedDateTime, Hour})
            @test collect(r) == [
                LaxZonedDateTime(DateTime(2016, 3, 13, 5, 45), winnipeg),
                LaxZonedDateTime(DateTime(2016, 3, 13, 4, 45), winnipeg),
                LaxZonedDateTime(DateTime(2016, 3, 13, 3, 45), winnipeg),
                LaxZonedDateTime(DateTime(2016, 3, 13, 1, 45), winnipeg),   # Skip DNE
                LaxZonedDateTime(DateTime(2016, 3, 13, 0, 45), winnipeg)
            ]

            # step past DNE (daily)
            start = LaxZonedDateTime(DateTime(2016, 3, 11, 2, 45), winnipeg)
            finish = LaxZonedDateTime(DateTime(2016, 3, 16, 2, 45), winnipeg)
            r = start:Day(2):finish
            @test isa(r, StepRange{LaxZonedDateTime, Day})
            @test collect(r) == [
                LaxZonedDateTime(DateTime(2016, 3, 11, 2, 45), winnipeg),
                LaxZonedDateTime(DateTime(2016, 3, 13, 2, 45), winnipeg),   # Include DNE
                LaxZonedDateTime(DateTime(2016, 3, 15, 2, 45), winnipeg)
            ]

            # step past DNE (daily, backward)
            start = LaxZonedDateTime(DateTime(2016, 3, 15, 2, 45), winnipeg)
            finish = LaxZonedDateTime(DateTime(2016, 3, 10, 2, 45), winnipeg)
            r = start:Day(-2):finish
            @test isa(r, StepRange{LaxZonedDateTime, Day})
            @test collect(r) == [
                LaxZonedDateTime(DateTime(2016, 3, 15, 2, 45), winnipeg),
                LaxZonedDateTime(DateTime(2016, 3, 13, 2, 45), winnipeg),   # Include DNE
                LaxZonedDateTime(DateTime(2016, 3, 11, 2, 45), winnipeg)
            ]

            # step past AMB (hourly)
            start = LaxZonedDateTime(DateTime(2016, 11, 6, 0, 45), winnipeg)
            finish = LaxZonedDateTime(DateTime(2016, 11, 6, 5, 45), winnipeg)
            r = start:Hour(1):finish
            @test isa(r, StepRange{LaxZonedDateTime, Hour})
            @test collect(r) == [
                LaxZonedDateTime(DateTime(2016, 11, 6, 0, 45), winnipeg),
                LaxZonedDateTime(ZonedDateTime(2016, 11, 6, 1, 45, winnipeg, 1)),
                LaxZonedDateTime(ZonedDateTime(2016, 11, 6, 1, 45, winnipeg, 2)),
                LaxZonedDateTime(DateTime(2016, 11, 6, 2, 45), winnipeg),
                LaxZonedDateTime(DateTime(2016, 11, 6, 3, 45), winnipeg),
                LaxZonedDateTime(DateTime(2016, 11, 6, 4, 45), winnipeg),
                LaxZonedDateTime(DateTime(2016, 11, 6, 5, 45), winnipeg)
            ]

            # step past AMB (hourly, backward)
            r = finish:Hour(-1):start
            @test isa(r, StepRange{LaxZonedDateTime, Hour})
            @test collect(r) == [
                LaxZonedDateTime(DateTime(2016, 11, 6, 5, 45), winnipeg),
                LaxZonedDateTime(DateTime(2016, 11, 6, 4, 45), winnipeg),
                LaxZonedDateTime(DateTime(2016, 11, 6, 3, 45), winnipeg),
                LaxZonedDateTime(DateTime(2016, 11, 6, 2, 45), winnipeg),
                LaxZonedDateTime(ZonedDateTime(2016, 11, 6, 1, 45, winnipeg, 2)),
                LaxZonedDateTime(ZonedDateTime(2016, 11, 6, 1, 45, winnipeg, 1)),
                LaxZonedDateTime(DateTime(2016, 11, 6, 0, 45), winnipeg)
            ]

            # step past AMB (daily)
            start = LaxZonedDateTime(DateTime(2016, 11, 4, 1, 45), winnipeg)
            finish = LaxZonedDateTime(DateTime(2016, 11, 9, 1, 45), winnipeg)
            r = start:Day(2):finish
            @test isa(r, StepRange{LaxZonedDateTime, Day})
            @test collect(r) == [
                LaxZonedDateTime(DateTime(2016, 11, 4, 1, 45), winnipeg),
                LaxZonedDateTime(DateTime(2016, 11, 6, 1, 45), winnipeg),   # Include AMB
                LaxZonedDateTime(DateTime(2016, 11, 8, 1, 45), winnipeg)
            ]

            # step past AMB (daily, backward)
            start = LaxZonedDateTime(DateTime(2016, 11, 8, 1, 45), winnipeg)
            finish = LaxZonedDateTime(DateTime(2016, 11, 3, 1, 45), winnipeg)
            r = start:Day(-2):finish
            @test isa(r, StepRange{LaxZonedDateTime, Day})
            @test collect(r) == [
                LaxZonedDateTime(DateTime(2016, 11, 8, 1, 45), winnipeg),
                LaxZonedDateTime(DateTime(2016, 11, 6, 1, 45), winnipeg),   # Include AMB
                LaxZonedDateTime(DateTime(2016, 11, 4, 1, 45), winnipeg)
            ]
        end

        @testset "start with invalid" begin
            # start is unrepresentable
            start = LaxZonedDateTime()
            finish = LaxZonedDateTime(DateTime(2016, 3, 13, 8, 45), winnipeg)
            r = start:Hour(1):finish
            @test isa(r, StepRange{LaxZonedDateTime, Hour})
            @test isempty(collect(r))

            r = start:Hour(-1):finish
            @test isa(r, StepRange{LaxZonedDateTime, Hour})
            @test isempty(collect(r))

            r = start:Day(2):finish
            @test isa(r, StepRange{LaxZonedDateTime, Day})
            @test isempty(collect(r))

            r = start:Day(-2):finish
            @test isa(r, StepRange{LaxZonedDateTime, Day})
            @test isempty(collect(r))

            # start is DNE
            start = LaxZonedDateTime(DateTime(2016, 3, 13, 2, 45), winnipeg)
            finish = LaxZonedDateTime(DateTime(2016, 3, 13, 7, 45), winnipeg)
            r = start:Hour(1):finish
            @test isa(r, StepRange{LaxZonedDateTime, Hour})
            @test isempty(collect(r))

            start = LaxZonedDateTime(DateTime(2016, 3, 13, 2, 45), winnipeg)
            finish = LaxZonedDateTime(DateTime(2016, 3, 12, 21, 45), winnipeg)
            r = start:Hour(-1):finish
            @test isa(r, StepRange{LaxZonedDateTime, Hour})
            @test isempty(collect(r))

            start = LaxZonedDateTime(DateTime(2016, 3, 13, 2, 45), winnipeg)
            finish = LaxZonedDateTime(DateTime(2016, 3, 18, 2, 45), winnipeg)
            r = start:Day(2):finish
            @test isa(r, StepRange{LaxZonedDateTime, Day})
            @test collect(r) == [
                LaxZonedDateTime(DateTime(2016, 3, 13, 2, 45), winnipeg),   # Include DNE
                LaxZonedDateTime(DateTime(2016, 3, 15, 2, 45), winnipeg),
                LaxZonedDateTime(DateTime(2016, 3, 17, 2, 45), winnipeg)
            ]

            start = LaxZonedDateTime(DateTime(2016, 3, 13, 2, 45), winnipeg)
            finish = LaxZonedDateTime(DateTime(2016, 3, 8, 2, 45), winnipeg)
            r = start:Day(-2):finish
            @test isa(r, StepRange{LaxZonedDateTime, Day})
            @test collect(r) == [
                LaxZonedDateTime(DateTime(2016, 3, 13, 2, 45), winnipeg),   # Include DNE
                LaxZonedDateTime(DateTime(2016, 3, 11, 2, 45), winnipeg),
                LaxZonedDateTime(DateTime(2016, 3, 9, 2, 45), winnipeg)
            ]

            # start is AMB
            start = LaxZonedDateTime(DateTime(2016, 11, 6, 1, 45), winnipeg)
            finish = LaxZonedDateTime(DateTime(2016, 11, 6, 6, 45), winnipeg)
            r = start:Hour(1):finish
            @test isa(r, StepRange{LaxZonedDateTime, Hour})
            @test isempty(collect(r))

            start = LaxZonedDateTime(DateTime(2016, 11, 6, 1, 45), winnipeg)
            finish = LaxZonedDateTime(DateTime(2016, 11, 5, 20, 45), winnipeg)
            r = start:Hour(-1):finish
            @test isa(r, StepRange{LaxZonedDateTime, Hour})
            @test isempty(collect(r))

            start = LaxZonedDateTime(DateTime(2016, 11, 6, 1, 45), winnipeg)
            finish = LaxZonedDateTime(DateTime(2016, 11, 11, 1, 45), winnipeg)
            r = start:Day(2):finish
            @test isa(r, StepRange{LaxZonedDateTime, Day})
            @test collect(r) == [
                LaxZonedDateTime(DateTime(2016, 11, 6, 1, 45), winnipeg),   # Include AMB
                LaxZonedDateTime(DateTime(2016, 11, 8, 1, 45), winnipeg),
                LaxZonedDateTime(DateTime(2016, 11, 10, 1, 45), winnipeg)
            ]

            start = LaxZonedDateTime(DateTime(2016, 11, 6, 1, 45), winnipeg)
            finish = LaxZonedDateTime(DateTime(2016, 11, 1, 1, 45), winnipeg)
            r = start:Day(-2):finish
            @test isa(r, StepRange{LaxZonedDateTime, Day})
            @test collect(r) == [
                LaxZonedDateTime(DateTime(2016, 11, 6, 1, 45), winnipeg),   # Include AMB
                LaxZonedDateTime(DateTime(2016, 11, 4, 1, 45), winnipeg),
                LaxZonedDateTime(DateTime(2016, 11, 2, 1, 45), winnipeg)
            ]
        end

        @testset "finish with invalid" begin
            # finish is unrepresentable
            start = LaxZonedDateTime(DateTime(2016, 3, 13, 3, 45), winnipeg)
            finish = LaxZonedDateTime()
            r = start:Hour(1):finish
            @test isa(r, StepRange{LaxZonedDateTime, Hour})
            @test isempty(collect(r))

            r = start:Hour(-1):finish
            @test isa(r, StepRange{LaxZonedDateTime, Hour})
            @test isempty(collect(r))

            r = start:Day(2):finish
            @test isa(r, StepRange{LaxZonedDateTime, Day})
            @test isempty(collect(r))

            r = start:Day(-2):finish
            @test isa(r, StepRange{LaxZonedDateTime, Day})
            @test isempty(collect(r))

            # finish is DNE
            start = LaxZonedDateTime(DateTime(2016, 3, 12, 21, 45), winnipeg)
            finish = LaxZonedDateTime(DateTime(2016, 3, 13, 2, 45), winnipeg)
            r = start:Hour(1):finish
            @test isa(r, StepRange{LaxZonedDateTime, Hour})
            @test collect(r) == [
                LaxZonedDateTime(DateTime(2016, 3, 12, 21, 45), winnipeg),
                LaxZonedDateTime(DateTime(2016, 3, 12, 22, 45), winnipeg),
                LaxZonedDateTime(DateTime(2016, 3, 12, 23, 45), winnipeg),
                LaxZonedDateTime(DateTime(2016, 3, 13, 0, 45), winnipeg),
                LaxZonedDateTime(DateTime(2016, 3, 13, 1, 45), winnipeg)    # Skip DNE
            ]

            start = LaxZonedDateTime(DateTime(2016, 3, 13, 7, 45), winnipeg)
            finish = LaxZonedDateTime(DateTime(2016, 3, 13, 2, 45), winnipeg)
            r = start:Hour(-1):finish
            @test isa(r, StepRange{LaxZonedDateTime, Hour})
            @test collect(r) == [
                LaxZonedDateTime(DateTime(2016, 3, 13, 7, 45), winnipeg),
                LaxZonedDateTime(DateTime(2016, 3, 13, 6, 45), winnipeg),
                LaxZonedDateTime(DateTime(2016, 3, 13, 5, 45), winnipeg),
                LaxZonedDateTime(DateTime(2016, 3, 13, 4, 45), winnipeg),
                LaxZonedDateTime(DateTime(2016, 3, 13, 3, 45), winnipeg)    # Skip DNE
            ]

            start = LaxZonedDateTime(DateTime(2016, 3, 9, 2, 45), winnipeg)
            finish = LaxZonedDateTime(DateTime(2016, 3, 13, 2, 45), winnipeg)
            r = start:Day(2):finish
            @test isa(r, StepRange{LaxZonedDateTime, Day})
            @test collect(r) == [
                LaxZonedDateTime(DateTime(2016, 3, 9, 2, 45), winnipeg),
                LaxZonedDateTime(DateTime(2016, 3, 11, 2, 45), winnipeg),
                LaxZonedDateTime(DateTime(2016, 3, 13, 2, 45), winnipeg)    # Include DNE
            ]

            start = LaxZonedDateTime(DateTime(2016, 3, 17, 2, 45), winnipeg)
            finish = LaxZonedDateTime(DateTime(2016, 3, 13, 2, 45), winnipeg)
            r = start:Day(-2):finish
            @test isa(r, StepRange{LaxZonedDateTime, Day})
            @test collect(r) == [
                LaxZonedDateTime(DateTime(2016, 3, 17, 2, 45), winnipeg),
                LaxZonedDateTime(DateTime(2016, 3, 15, 2, 45), winnipeg),
                LaxZonedDateTime(DateTime(2016, 3, 13, 2, 45), winnipeg)    # Include DNE
            ]

            # finish is AMB
            start = LaxZonedDateTime(DateTime(2016, 11, 5, 20, 45), winnipeg)
            finish = LaxZonedDateTime(DateTime(2016, 11, 6, 1, 45), winnipeg)
            r = start:Hour(1):finish
            @test isa(r, StepRange{LaxZonedDateTime, Hour})
            @test collect(r) == [
                LaxZonedDateTime(DateTime(2016, 11, 5, 20, 45), winnipeg),
                LaxZonedDateTime(DateTime(2016, 11, 5, 21, 45), winnipeg),
                LaxZonedDateTime(DateTime(2016, 11, 5, 22, 45), winnipeg),
                LaxZonedDateTime(DateTime(2016, 11, 5, 23, 45), winnipeg),
                LaxZonedDateTime(DateTime(2016, 11, 6, 0, 45), winnipeg),
                LaxZonedDateTime(ZonedDateTime(2016, 11, 6, 1, 45, winnipeg, 1)),
                LaxZonedDateTime(ZonedDateTime(2016, 11, 6, 1, 45, winnipeg, 2))
            ]

            start = LaxZonedDateTime(DateTime(2016, 11, 6, 6, 45), winnipeg)
            finish = LaxZonedDateTime(DateTime(2016, 11, 6, 1, 45), winnipeg)
            r = start:Hour(-1):finish
            @test isa(r, StepRange{LaxZonedDateTime, Hour})
            @test collect(r) == [
                LaxZonedDateTime(DateTime(2016, 11, 6, 6, 45), winnipeg),
                LaxZonedDateTime(DateTime(2016, 11, 6, 5, 45), winnipeg),
                LaxZonedDateTime(DateTime(2016, 11, 6, 4, 45), winnipeg),
                LaxZonedDateTime(DateTime(2016, 11, 6, 3, 45), winnipeg),
                LaxZonedDateTime(DateTime(2016, 11, 6, 2, 45), winnipeg),
                LaxZonedDateTime(ZonedDateTime(2016, 11, 6, 1, 45, winnipeg, 2)),
                LaxZonedDateTime(ZonedDateTime(2016, 11, 6, 1, 45, winnipeg, 1))
            ]

            start = LaxZonedDateTime(DateTime(2016, 11, 2, 1, 45), winnipeg)
            finish = LaxZonedDateTime(DateTime(2016, 11, 6, 1, 45), winnipeg)
            r = start:Day(2):finish
            @test isa(r, StepRange{LaxZonedDateTime, Day})
            @test collect(r) == [
                LaxZonedDateTime(DateTime(2016, 11, 2, 1, 45), winnipeg),
                LaxZonedDateTime(DateTime(2016, 11, 4, 1, 45), winnipeg),
                LaxZonedDateTime(DateTime(2016, 11, 6, 1, 45), winnipeg)    # Include AMB
            ]

            start = LaxZonedDateTime(DateTime(2016, 11, 10, 1, 45), winnipeg)
            finish = LaxZonedDateTime(DateTime(2016, 11, 6, 1, 45), winnipeg)
            r = start:Day(-2):finish
            @test isa(r, StepRange{LaxZonedDateTime, Day})
            @test collect(r) == [
                LaxZonedDateTime(DateTime(2016, 11, 10, 1, 45), winnipeg),
                LaxZonedDateTime(DateTime(2016, 11, 8, 1, 45), winnipeg),
                LaxZonedDateTime(DateTime(2016, 11, 6, 1, 45), winnipeg)    # Include AMB
            ]
        end
    end

    @testset "ZonedDateTime" begin
        zdt = ZonedDateTime(DateTime(2016, 11, 10, 1, 45), winnipeg)
        lzdt = LaxZonedDateTime(DateTime(2016, 11, 10, 1, 45), winnipeg)
        dne = LaxZonedDateTime(DateTime(2015, 3, 8, 2), winnipeg)
        nonamb = LaxZonedDateTime(ZonedDateTime(2017, 11, 6, 1, 45, winnipeg, 1))
        amb1 = LaxZonedDateTime(DateTime(2016, 11, 6, 1, 45), winnipeg)
        amb2 = LaxZonedDateTime(DateTime(2017, 11, 5, 1, 45), winnipeg)

        @testset "isequal" begin
            @test isequal(zdt, lzdt)
            @test isequal(lzdt, zdt)
            @test !isequal(zdt, dne)
            @test isequal(dne, dne)
            @test !isequal(amb1, amb2)
            @test isequal(amb1 + Hour(1), amb2 + Hour(1))
            @test !isequal(amb1, nonamb)
        end

        @testset "hash" begin
            @test hash(zdt) == hash(lzdt)
            @test hash(zdt) != hash(dne)
            @test hash(dne) == hash(dne)
            @test hash(amb1) != hash(amb2)
            @test hash(amb1 + Hour(1)) == hash(amb2 + Hour(1))
        end
    end

    include("intervals.jl")
end
