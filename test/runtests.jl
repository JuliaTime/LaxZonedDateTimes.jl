using LaxZonedDateTimes
using Base.Test
using TimeZones
import TimeZones: Transition
import Base.Dates: Year, Month, Week, Day, Hour, Minute, Second
import LaxZonedDateTimes: NonExistent, isrepresentable

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
@test non_existent_a + Hour(1) == null
@test non_existent_b + Hour(1) == null

ambiguous = LaxZonedDateTime(DateTime(1960,4,1,12),t)

@test non_existent_a + Hour(0) == null
@test non_existent_b + Hour(0) == null
@test ambiguous + Hour(0) == null

@test ambiguous - Hour(1) == null
@test ambiguous + Hour(1) == null


wpg = TimeZone("America/Winnipeg")
lzdt = LaxZonedDateTime(ZonedDateTime(2015,3,7,2, wpg))
lzdt += Day(1)
@test lzdt == LaxZonedDateTime(DateTime(2015,3,8,2), wpg, NonExistent())
lzdt += Day(1)
@test lzdt == LaxZonedDateTime(ZonedDateTime(2015,3,9,2,wpg))

non_existent = LaxZonedDateTime(DateTime(2015,3,8,2), wpg, NonExistent())
@test non_existent + Hour(1) == LaxZonedDateTime()
@test non_existent - Hour(1) == LaxZonedDateTime()
@test non_existent + Hour(0) == LaxZonedDateTime()
@test non_existent - Hour(0) == LaxZonedDateTime()

@test (non_existent + Hour(1)) + Hour(1) == LaxZonedDateTime()
@test (non_existent + Hour(1)) + Day(1) == LaxZonedDateTime()

#=
using Base.Dates
using TimeZones

r = ZonedDateTime(2015,3,9,1,wpg):Hour(1):ZonedDateTime(2015,3,10,wpg)
a = collect(r)

l = map(LaxZonedDateTime, a)
l - Day(1)
=#

wpg = TimeZone("America/Winnipeg")
@test LaxZonedDateTime(ZonedDateTime(2014,wpg)) < ZonedDateTime(2015,wpg)

amb = LaxZonedDateTime(DateTime(2015,11,1,1),wpg)
amb_first = LaxZonedDateTime(ZonedDateTime(2015,11,1,1,wpg,1))
amb_last = LaxZonedDateTime(ZonedDateTime(2015,11,1,1,wpg,2))

@test amb_first < amb_last
@test !(amb_first < amb)
@test !(amb < amb_first)
@test !(amb_last < amb)
@test !(amb < amb_last)

non_existent = LaxZonedDateTime(DateTime(2015,3,8,2),wpg)
@test ZonedDateTime(2015,3,8,1,wpg) < non_existent < ZonedDateTime(2015,3,8,3,wpg)


@test hour(amb) == hour(amb_first) == hour(amb_last) == 1
@test hour(non_existent) == 2

@test month(amb) == 11

@test_throws Exception localtime(null)
@test_throws Exception utc(null)
@test_throws Exception hour(null)


a = ZonedDateTime(2016, 11, 6, 1, 30, wpg, 1)
b = ZonedDateTime(2016, 11, 6, 1, wpg, 2)

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


@testset "rounding" begin
    winnipeg = TimeZone("America/Winnipeg")
    st_johns = TimeZone("America/St_Johns")     # UTC-3:30 (or UTC-2:30)
    eucla = TimeZone("Australia/Eucla")         # UTC+8:45
    colombo = TimeZone("Asia/Colombo")          # See note below

    # On 1996-05-25 at 00:00, the Asia/Colombo time zone in Sri Lanka moved from Indian
    # Standard Time (UTC+5:30) to Lanka Time (UTC+6:30). On 1996-10-26 at 00:30, Lanka Time
    # was revised from UTC+6:30 to UTC+6:00, marking a -00:30 transition.  Transitions like
    # these are doubly unusual (compared to the more common DST transitions) as it is both
    # an half-hour transition and a transition that lands at midnight (causing
    # 1996-10-26T00:00 to be ambiguous; midnights are rarely ambiguous). In 2006,
    # Asia/Colombo returned to Indian Standard Time, causing another -00:30 transition from
    # 00:30 to 00:00.

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
        # missing date results in something unrepresentable (because `round` can't figure
        # out whether to use the result from `floor` or `ceil`).
        lzdt = LaxZonedDateTime(DateTime(1996, 10, 25, 23, 45), colombo)
        @test round(lzdt, Hour) == LaxZonedDateTime(ZonedDateTime(1996, 10, 26, colombo, 1))
        @test !isrepresentable(round(lzdt, Day))

        # Rounding ambiguous or missing dates to a `TimePeriod` results in unrepresentable
        # values.
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
