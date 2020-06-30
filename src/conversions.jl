function TimeZones.astimezone(zdt::LaxZonedDateTime, tz::TimeZone)
    if isvalid(zdt)
        return LaxZonedDateTime(astimezone(ZonedDateTime(zdt), tz))
    else
        return LaxZonedDateTime()
    end
end

function TimeZones.astimezone(i::Interval{LaxZonedDateTime, L, R}, tz::TimeZone) where {L,R}
    return Interval{LaxZonedDateTime, L,R}(astimezone(first(i), tz), astimezone(last(i), tz))
end

function TimeZones.astimezone(i::AnchoredInterval{P, LaxZonedDateTime, L, R}, tz::TimeZone) where {P,L,R}
    return AnchoredInterval{P, LaxZonedDateTime, L, R}(astimezone(anchor(i), tz))
end
