# LaxZonedDateTimes
[![latest](https://img.shields.io/badge/docs-latest-blue.svg)](https://juliatime.github.io/LaxZonedDateTimes.jl/stable/)
[![dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://juliatime.github.io/LaxZonedDateTimes.jl/dev/)
[![build status](https://github.com/JuliaTime/LaxZonedDateTimes.jl/workflows/CI/badge.svg)](https://github.com/JuliaTime/LaxZonedDateTimes.jl/commits/master)

Provides `LaxZonedDateTime`, an alternative to TimeZones.jl's `ZonedDateTime` that does
not raise exceptions when a time that is ambiguous or doesn't exist is encountered.

## Examples

```julia
julia> using LaxZonedDateTimes, TimeZones

julia> winnipeg = TimeZone("America/Winnipeg")
America/Winnipeg (UTC-6/UTC-5)

julia> LaxZonedDateTime(DateTime(2016), winnipeg)
2016-01-01T00:00:00-06:00

julia> LaxZonedDateTime(DateTime(2016, 3, 13, 2, 45), winnipeg)
2016-03-13T02:45:00-DNE

julia> LaxZonedDateTime(DateTime(2016, 11, 6, 1, 45), winnipeg)
2016-11-06T01:45:00-AMB
```

One of the advantages of using `LaxZonedDateTime`s is that when you encounter a time
that is ambiguous or doesn't exist, you don't lose the information. For example,
consider the following case:

```julia
julia> lzdt = LaxZonedDateTime(DateTime(2016, 3, 12, 2), winnipeg)
2016-03-11T02:00:00-06:00

julia> nonexistent = lzdt + Dates.Day(1)
2016-03-13T02:00:00-DNE

julia> nonexistent + Dates.Day(1)
2016-03-14T02:00:00-05:00
```

In some cases, however, it's difficult to determine what the result should be. While
arithmetic with `DatePeriod`s will always work, attempting to add or subtract a
`TimePeriod` value from an ambiguous or nonexistent `LaxZonedDateTime` will result in an
unrepresentable value (which is an unrecoverable state):

```julia
julia> lzdt = LaxZonedDateTime(DateTime(2016, 3, 13, 2), winnipeg)
2016-03-13T02:00:00-DNE

julia> lzdt + Dates.Hour(2)
INVALID
```

You can test a `LaxZonedDateTime` for validity using `isnonexistent`, `isambiguous`, and
`isvalid` (the last of which returns `false` if the value is nonexistent, ambiguous, or
unrepresentable).

## Ranges

```julia
julia> lzdt = LaxZonedDateTime(DateTime(2016, 3, 11, 2), winnipeg)
2016-03-11T02:00:00-06:00

julia> r = lzdt:Dates.Day(1):(lzdt + Dates.Day(5))
2016-03-16T02:00:00-05:002016-03-11T02:00:00-06:00

julia> collect(r)
6-element Array{LaxZonedDateTimes.LaxZonedDateTime,1}:
 2016-03-11T02:00:00-06:00
 2016-03-12T02:00:00-06:00
 2016-03-13T02:00:00-DNE
 2016-03-14T02:00:00-05:00
 2016-03-15T02:00:00-05:00
 2016-03-16T02:00:00-05:00
```

Notice that the third element represents a nonexistent time (a time that has no UTC
representation).

Note that ambiguous and nonexistent values only occur in places where a `ZonedDateTime`
would raise an exception. Here, we step right past the nonexistent time:

```julia
julia> lzdt = LaxZonedDateTime(DateTime(2016, 3, 13), TimeZone("America/Winnipeg"))
2016-03-13T00:00:00-06:00

julia> r = lzdt:Dates.Hour(1):(lzdt + Dates.Hour(5))
2016-03-16T02:00:00-05:002016-03-11T02:00:00-06:00

julia> collect(r)
6-element Array{LaxZonedDateTimes.LaxZonedDateTime,1}:
 2016-03-13T00:00:00-06:00
 2016-03-13T01:00:00-06:00
 2016-03-13T03:00:00-05:00
 2016-03-13T04:00:00-05:00
 2016-03-13T05:00:00-05:00
 2016-03-13T06:00:00-05:00
```

Ranges should generally work as expected, but here are the rules for some of the edge
cases that you might encounter:

* If start and/or finish is unrepresentable, the range collects to nothing
* If start is AMB/DNE, and step is a `DatePeriod`, it works (first element will be
  DNE/AMB)
* If start is AMB/DNE, and step is a `TimePeriod`, the range collects to nothing
* If finish is AMB/DNE, and step is a `DatePeriod`, it works (last element may be
  DNE/AMB)
* If finish is AMB/DNE, and step is a `TimePeriod`, it works (last element omitted for
  DNE, both versions included for AMB)

(The last two descriptions above assume that step divides evenly into the range. If it
doesn't, then the last element won't actually hit the AMB/DNE value.)

When transitions occur between the start and end of a range, they are skipped over as per
the TimeZones.jl implementation (e.g., when stepping one hour at a time, a "spring
forward" will result in the range collecting to 0:00, 1:00, 3:00, ...). A DNE
`LaxZonedDateTime` will only appear in cases where TimeZones.jl would throw an error
(e.g., stepping through the "spring forward" transition one day at a time, and landing on
the missing hour).
