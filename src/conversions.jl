function TimeZones.astimezone(zdt::LaxZonedDateTime, tz::TimeZone)
    if isvalid(zdt)
        return LaxZonedDateTime(astimezone(ZonedDateTime(zdt), tz))
    else
        return LaxZonedDateTime()
    end
end

function TimeZones.astimezone(i::Interval{LaxZonedDateTime}, tz::TimeZone)
    return Interval(astimezone(first(i), tz), astimezone(last(i), tz), inclusivity(i))
end

function TimeZones.astimezone(i::AnchoredInterval{P, LaxZonedDateTime}, tz::TimeZone) where P
    return AnchoredInterval{P, LaxZonedDateTime}(astimezone(anchor(i), tz), inclusivity(i))
end