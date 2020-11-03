using Dates: days, hour, minute, second, millisecond

function Dates.DateTime(lzdt::LaxZonedDateTime)
    if isrepresentable(lzdt)
        return lzdt.local_datetime
    else
        error("Unable to determine local datetime from an unrepresentable LaxZonedDateTime")
    end
end

Dates.DateTime(lzdt::LaxZonedDateTime, ::Type{UTC}) = DateTime(ZonedDateTime(lzdt), UTC)

Dates.Date(lzdt::LaxZonedDateTime) = Date(DateTime(lzdt))
Dates.Date(lzdt::LaxZonedDateTime, ::Type{UTC}) = Date(DateTime(lzdt, UTC))

Dates.Time(lzdt::LaxZonedDateTime) = Time(DateTime(lzdt))
Dates.Time(lzdt::LaxZonedDateTime, ::Type{UTC}) = Time(DateTime(lzdt, UTC))

TimeZones.timezone(lzdt::LaxZonedDateTime) = lzdt.timezone

"""
    isrepresentable(lzdt::LaxZonedDateTime) -> Bool

Indicates whether a `LaxZonedDateTime` can be represented by a local `DateTime`. Both valid
and invalid time are representable where as unknown time is not representable.
"""
isrepresentable(lzdt::LaxZonedDateTime) = lzdt.representable

"""
    isvalid(lzdt::LaxZonedDateTime) -> Bool

Indicates if a `LaxZonedDateTime` is a valid time. Valid time can always be represented as a
UTC instant.
"""
Base.isvalid(lzdt::LaxZonedDateTime) = isrepresentable(lzdt) && !isa(lzdt.zone, InvalidTimeZone)

"""
    isinvalid(lzdt::LaxZonedDateTime) -> Bool

Indicates if a `LaxZonedDateTime` is an invalid time. Invalid time is representable in local
time but is not representable as a UTC instant.
"""
isinvalid(lzdt::LaxZonedDateTime) = isrepresentable(lzdt) && isa(lzdt.zone, InvalidTimeZone)

isambiguous(lzdt::LaxZonedDateTime) = isa(lzdt.zone, Ambiguous)
isnonexistent(lzdt::LaxZonedDateTime) = isa(lzdt.zone, NonExistent)

Dates.days(lzdt::LaxZonedDateTime) = days(DateTime(lzdt))

for period in (:Hour, :Minute, :Second, :Millisecond)
    accessor = Symbol(lowercase(string(period)))
    @eval begin
        Dates.$accessor(lzdt::LaxZonedDateTime) = $accessor(DateTime(lzdt))
        Dates.$period(lzdt::LaxZonedDateTime) = $period($accessor(lzdt))
    end
end
