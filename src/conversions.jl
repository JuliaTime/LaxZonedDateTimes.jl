function TimeZones.astimezone(zdt::LaxZonedDateTime, tz::TimeZone)
    if isvalid(zdt)
        return LaxZonedDateTime(astimezone(ZonedDateTime(zdt), tz))
    else
        return LaxZonedDateTime()
    end
end