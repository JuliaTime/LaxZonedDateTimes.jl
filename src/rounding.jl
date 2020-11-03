using Dates: Period, DatePeriod, TimePeriod, floorceil

function Base.floor(lzdt::LaxZonedDateTime, p::DatePeriod)
    return LaxZonedDateTime(floor(DateTime(lzdt), p), timezone(lzdt))
end

function Base.floor(lzdt::LaxZonedDateTime, p::TimePeriod)
    # Rounding non-representable dates doesn't work.
    !isrepresentable(lzdt) && (return LaxZonedDateTime())

    local_dt = DateTime(lzdt)
    local_dt_floored = floor(local_dt, p)

    if local_dt == local_dt_floored
        lzdt
    elseif isvalid(lzdt)
        # Rounding is done using the current fixed offset to avoid transitional ambiguities.
        utc_dt_floored = local_dt_floored - lzdt.zone.offset
        LaxZonedDateTime(ZonedDateTime(utc_dt_floored, timezone(lzdt); from_utc=true))
    else
        LaxZonedDateTime()
    end
end

function Base.ceil(lzdt::LaxZonedDateTime, p::DatePeriod)
    return LaxZonedDateTime(ceil(DateTime(lzdt), p), timezone(lzdt))
end

# TODO: Additional performance gains can be made for round

function Base.round(lzdt::LaxZonedDateTime, p::DatePeriod, r::RoundingMode{:NearestTiesUp})
    f, c = floorceil(lzdt, p)

    if f == c
        f
    elseif isvalid(f) && isvalid(c)
        local_dt = DateTime(lzdt)
        local_dt - DateTime(f) < DateTime(c) - local_dt ? f : c
    else
        LaxZonedDateTime()
    end
end

function Base.round(lzdt::LaxZonedDateTime, p::TimePeriod, r::RoundingMode{:NearestTiesUp})
    f, c = floorceil(lzdt, p)

    if f == c
        f
    elseif isvalid(f) && isvalid(c)
        utc_dt = DateTime(lzdt, UTC)
        utc_dt - DateTime(f, UTC) < DateTime(c, UTC) - utc_dt ? f : c
    else
        LaxZonedDateTime()
    end
end

"""
    floor(lzdt::LaxZonedDateTime, p::Period) -> LaxZonedDateTime
    floor(lzdt::LaxZonedDateTime, p::Type{Period}) -> LaxZonedDateTime

Returns the nearest `LaxZonedDateTime` less than or equal to `zdt` at resolution `p`. The
result will be in the same time zone as `lzdt`.

For convenience, `p` may be a type instead of a value: `floor(lzdt, Dates.Hour)` is a
shortcut for `floor(lzdt, Dates.Hour(1))`.

`VariableTimeZone` transitions are handled as for `round`.

### Examples

The `America/Winnipeg` time zone transitioned from Central Standard Time (UTC-6:00) to
Central Daylight Time (UTC-5:00) on 2016-03-13, moving directly from 01:59:59 to 03:00:00.

```julia
julia> lzdt = LaxZonedDateTime(DateTime(2016, 3, 13, 1, 45), TimeZone("America/Winnipeg"))
2016-03-13T01:45:00-06:00

julia> floor(lzdt, Dates.Hour)
2016-03-13T01:00:00-06:00

julia> floor(lzdt, Dates.Day)
2016-03-13T00:00:00-06:00
```

The `Asia/Colombo` time zone revised the definition of Lanka Time from UTC+6:30 to UTC+6:00
on 1996-10-26, moving from 00:29:59 back to 00:00:00.

```julia
julia> lzdt = LaxZonedDateTime(DateTime(1996, 10, 26, 0, 45), TimeZone("Asia/Colombo"))
1996-10-25T23:45:00+06:30

julia> floor(lzdt, Dates.Hour)
1996-10-26T00:00:00+06:00

julia> floor(lzdt, Dates.Day)
1996-10-26T00:00:00-AMB
```
"""
Base.floor(::LaxZonedDateTimes.LaxZonedDateTime, ::Union{Period, Type{Period}})

"""
    ceil(lzdt::ZonedDateTime, p::Period) -> LaxZonedDateTime
    ceil(lzdt::ZonedDateTime, p::Type{Period}) -> LaxZonedDateTime

Returns the nearest `LaxZonedDateTime` greater than or equal to `lzdt` at resolution `p`.
The result will be in the same time zone as `lzdt`.

For convenience, `p` may be a type instead of a value: `ceil(lzdt, Dates.Hour)` is a
shortcut for `ceil(lzdt, Dates.Hour(1))`.

`VariableTimeZone` transitions are handled as for `round`.

### Examples

The `America/Winnipeg` time zone transitioned from Central Standard Time (UTC-6:00) to
Central Daylight Time (UTC-5:00) on 2016-03-13, moving directly from 01:59:59 to 03:00:00.

```julia
julia> lzdt = LaxZonedDateTime(DateTime(2016, 3, 13, 1, 45), TimeZone("America/Winnipeg"))
2016-03-13T01:45:00-06:00

julia> ceil(lzdt, Dates.Day)
2016-03-14T00:00:00-05:00

julia> ceil(lzdt, Dates.Hour)
2016-03-13T03:00:00-05:00
```

The `Asia/Colombo` time zone revised the definition of Lanka Time from UTC+6:30 to UTC+6:00
on 1996-10-26, moving from 00:29:59 back to 00:00:00.

```julia
julia> lzdt = LaxZonedDateTime(DateTime(1996, 10, 25, 23, 45), TimeZone("Asia/Colombo"))
1996-10-25T23:45:00+06:30

julia> ceil(lzdt, Dates.Hour)
1996-10-26T00:00:00+06:30

julia> ceil(lzdt, Dates.Day)
1996-10-26T00:00:00-AMB
```
"""
Base.ceil(::LaxZonedDateTimes.LaxZonedDateTime, ::Union{Period, Type{Period}})

"""
    round(lzdt::ZonedDateTime, p::Period, [r::RoundingMode]) -> LaxZonedDateTime
    round(lzdt::ZonedDateTime, p::Type{Period}, [r::RoundingMode]) -> LaxZonedDateTime

Returns the `LaxZonedDateTime` nearest to `lzdt` at resolution `p`. The result will be in
the same time zone as `lzdt`. By default (`RoundNearestTiesUp`), ties (e.g., rounding 9:30
to the nearest hour) will be rounded up.

For convenience, `p` may be a type instead of a value: `round(lzdt, Dates.Hour)` is a
shortcut for `round(lzdt, Dates.Hour(1))`.

Valid rounding modes for `round(::TimeType, ::Period, ::RoundingMode)` are
`RoundNearestTiesUp` (default), `RoundDown` (`floor`), and `RoundUp` (`ceil`).

### `VariableTimeZone` Transitions

`LaxZonedDateTime`s, like `ZonedDateTime`s, are rounded in their local time zone (rather
than UTC). This ensures that rounding behaves as expected and is maximally meaningful.

If rounding were done in UTC, consider how rounding to the nearest day would be resolved for
non-UTC time zones: the result would be 00:00 UTC, which wouldn't be midnight local time.
Similarly, when rounding to the nearest hour in `Australia/Eucla (UTC+08:45)`, the result
wouldn't be on the hour in the local time zone.

When `p` is a `DatePeriod` rounding is done in the local time zone in a straightforward
fashion. When `p` is a `TimePeriod` the likelihood of encountering an ambiguous or
non-existent time (due to daylight saving time transitions) is increased. To resolve this
issue, rounding a `LaxZonedDateTime` with a `VariableTimeZone` to a `TimePeriod` uses the
`DateTime` value in the appropriate `FixedTimeZone`, then reconverts it to a
`LaxZonedDateTime` in the appropriate `VariableTimeZone` afterward.

While it might be tempting to suppose that both `DatePeriod`s and `TimePeriod`s should be
rounded in local time (allowing ambiguous or non-existent times to crop up where they may),
`LaxZonedDateTime` attempts to return the maintain consistency with `ZonedDateTime` wherever
possible. While this may be contentious, most parties can probably agree that 01:59 rounded
to the nearest hour on a "spring forward" day should return 03:00 (the next hour that
exists) instead of 02:00 (which is non-existent).

Rounding is not an entirely "safe" operation for `LaxZonedDateTime`s, as in some cases
historical transitions for some time zones (such as `Asia/Colombo`) occur at midnight. In
such cases rounding to a `DatePeriod` may still return a result marked as ambiguous or
non-existent. Unlike a `ZonedDateTime`, however, no exceptions will be thrown.

### Rounding Ambiguous or Non-Existent Times

Rounding a `LaxZonedDateTime` that is in an ambiguous or non-existent state to a
`DatePeriod` will function as expected (because most transitions do not occur on date
boundaries, this will typically return the `LaxZonedDatetime` to a valid state).

Rounding an ambiguous or non-existent `LaxZonedDateTime` to a `TimePeriod` will result in
a non-representable state that is unrecoverable.

When `round`ing a `LaxZonedDateTime` using `RoundNearestTiesUp`, `round` needs to decide
whether `floor` or `ceil` is "closer" to the original date. In cases where `floor` or `ceil` result
would return a result that is either ambiguous or non-existent, `round` is unable to
determine which result is to be preferred, and will return a non-representable
`LaxZonedDateTime`.

### Examples

The `America/Winnipeg` time zone transitioned from Central Standard Time (UTC-6:00) to
Central Daylight Time (UTC-5:00) on 2016-03-13, moving directly from 01:59:59 to 03:00:00.

```julia
julia> lzdt = LaxZonedDateTime(DateTime(2016, 3, 13, 1, 45), TimeZone("America/Winnipeg"))
2016-03-13T01:45:00-06:00

julia> round(lzdt, Dates.Hour)
2016-03-13T03:00:00-05:00

julia> round(lzdt, Dates.Day)
2016-03-13T00:00:00-06:00

julia> lzdt = LaxZonedDateTime(DateTime(2016, 3, 13, 2, 45), TimeZone("America/Winnipeg"))
2016-03-13T02:45:00-DNE

julia> round(lzdt, Dates.Hour)
INVALID
```

The `Asia/Colombo` time zone revised the definition of Lanka Time from UTC+6:30 to UTC+6:00
on 1996-10-26, moving from 00:29:59 back to 00:00:00.

```julia
julia> lzdt = LaxZonedDateTime(DateTime(1996, 10, 25, 23, 45), TimeZone("Asia/Colombo"))
1996-10-25T23:45:00+06:30

julia> round(lzdt, Dates.Hour)
1996-10-26T00:00:00+06:30

julia> round(lzdt, Dates.Day)
INVALID
```
"""     # Defined in base/dates/rounding.jl
Base.round(::LaxZonedDateTimes.LaxZonedDateTime, ::Union{Period, Type{Period}})
