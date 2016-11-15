import Base.Dates: hour, minute, second, millisecond

localtime(lzdt::LaxZonedDateTime) = lzdt.local_datetime
utc(lzdt::LaxZonedDateTime) = utc(ZonedDateTime(lzdt))
timezone(lzdt::LaxZonedDateTime) = lzdt.timezone
isrepresentable(lzdt::LaxZonedDateTime) = lzdt.representable

Base.isvalid(lzdt::LaxZonedDateTime) = isrepresentable(lzdt) && !isa(lzdt.zone, InvalidTimeZone)
isambiguous(lzdt::LaxZonedDateTime) = isa(lzdt, Ambiguous)
isnonexistent(lzdt::LaxZonedDateTime) = isa(lzdt, NonExistent)

days(lzdt::LaxZonedDateTime) = days(localtime(lzdt))

for period in (:Hour, :Minute, :Second, :Millisecond)
    accessor = Symbol(lowercase(string(period)))
    @eval begin
        $accessor(lzdt::LaxZonedDateTime) = $accessor(localtime(lzdt))
        $period(lzdt::LaxZonedDateTime) = $period($accessor(lzdt))
    end
end
