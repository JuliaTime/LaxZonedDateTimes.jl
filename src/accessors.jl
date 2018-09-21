import Compat.Dates: days, hour, minute, second, millisecond

function localtime(lzdt::LaxZonedDateTime)
    if isrepresentable(lzdt)
        return lzdt.local_datetime
    else
        error("Unable to determine local datetime from an unrepresentable LaxZonedDateTime")
    end
end

utc(lzdt::LaxZonedDateTime) = utc(ZonedDateTime(lzdt))
timezone(lzdt::LaxZonedDateTime) = lzdt.timezone

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

days(lzdt::LaxZonedDateTime) = days(localtime(lzdt))

for period in (:Hour, :Minute, :Second, :Millisecond)
    accessor = Symbol(lowercase(string(period)))
    @eval begin
        $accessor(lzdt::LaxZonedDateTime) = $accessor(localtime(lzdt))
        $period(lzdt::LaxZonedDateTime) = $period($accessor(lzdt))
    end
end
