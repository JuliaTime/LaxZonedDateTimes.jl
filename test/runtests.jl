using LaxZonedDateTimes
using Base.Test
using TimeZones
import TimeZones: Transition
import Base.Dates: Day, Hour
import LaxZonedDateTimes: NonExistent

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
