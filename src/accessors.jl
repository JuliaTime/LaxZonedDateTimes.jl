import Base.Dates: days, hour, minute, second, millisecond

function localtime(lzdt::LaxZonedDateTime)
    if isrepresentable(lzdt)
        return lzdt.local_datetime
    else
        error("Unable to determine local datetime from an unrepresentable LaxZonedDateTime")
    end
end

utc(lzdt::LaxZonedDateTime) = utc(ZonedDateTime(lzdt))
timezone(lzdt::LaxZonedDateTime) = lzdt.timezone
isrepresentable(lzdt::LaxZonedDateTime) = lzdt.representable

Base.isvalid(lzdt::LaxZonedDateTime) = isrepresentable(lzdt) && !isa(lzdt.zone, InvalidTimeZone)
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
