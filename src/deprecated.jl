using Base: @deprecate
using TimeZones: TimeZones

# BEGIN LaxZonedDateTimes 1.0 deprecations

if isdefined(TimeZones, :localtime) && isdefined(TimeZones, :utc)
    import TimeZones: localtime, utc
end

@deprecate localtime(lzdt::LaxZonedDateTime) DateTime(lzdt) true
@deprecate utc(lzdt::LaxZonedDateTime) DateTime(lzdt, UTC) true

@deprecate DateTime(lzdt::LaxZonedDateTime, ::Type{Local}) DateTime(lzdt)
@deprecate Date(lzdt::LaxZonedDateTime, ::Type{Local}) Date(lzdt)
@deprecate Time(lzdt::LaxZonedDateTime, ::Type{Local}) Time(lzdt)

# END LaxZonedDateTimes 1.0 deprecations
