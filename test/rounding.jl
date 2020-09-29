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

    periods = (Year, Month, Week, Day, Hour, Minute, Second)

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
    end

    @testset "non-existent" begin
        dne_lzdt = LaxZonedDateTime(DateTime(2016, 3, 13, 2, 0, 0, 1), winnipeg)
        @test !isvalid(dne_lzdt)
        @test !isambiguous(dne_lzdt)
        @test isnonexistent(dne_lzdt)
        @test isrepresentable(dne_lzdt)

        @testset "$(nameof(P))" for P in periods, f in (floor, ceil, round)
            result = f(dne_lzdt, P)

            if P <: DatePeriod
                @test isrepresentable(result)
            else
                @test !isrepresentable(result)
            end
        end
    end

    @testset "ambiguous" begin
        amb_lzdt = LaxZonedDateTime(DateTime(2015, 11, 1, 1, 0, 0, 1), winnipeg)
        @test !isvalid(amb_lzdt)
        @test isambiguous(amb_lzdt)
        @test !isnonexistent(amb_lzdt)
        @test isrepresentable(amb_lzdt)

        @testset "$(nameof(P))" for P in periods, f in (floor, ceil, round)
            result = f(amb_lzdt, P)

            if P <: DatePeriod
                @test isrepresentable(result)
            else
                @test !isrepresentable(result)
            end
        end
    end

    @testset "non-existent rounded" begin
        dne_lzdt = LaxZonedDateTime(DateTime(2016, 3, 13, 2), winnipeg)
        @test isnonexistent(dne_lzdt)

        @test floor(dne_lzdt, Hour) == dne_lzdt
        @test ceil(dne_lzdt, Hour) == dne_lzdt
        @test round(dne_lzdt, Hour) == dne_lzdt
    end

    @testset "ambiguous rounded" begin
        amb_lzdt = LaxZonedDateTime(DateTime(2015, 11, 1, 1), winnipeg)
        @test isambiguous(amb_lzdt)

        @test floor(amb_lzdt, Hour) == amb_lzdt
        @test ceil(amb_lzdt, Hour) == amb_lzdt
        @test round(amb_lzdt, Hour) == amb_lzdt
    end
end