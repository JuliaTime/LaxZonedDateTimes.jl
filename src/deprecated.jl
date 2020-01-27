using Base: @deprecate
using TimeZones: TimeZones

# BEGIN LaxZonedDateTimes 1.0 deprecations

if isdefined(TimeZones, :localtime) && isdefined(TimeZones, :utc)
    import TimeZones: localtime, utc
end

@deprecate localtime(lzdt::LaxZonedDateTime) DateTime(lzdt, Local) true
@deprecate utc(lzdt::LaxZonedDateTime) DateTime(lzdt, UTC) true

# END LaxZonedDateTimes 1.0 deprecations
