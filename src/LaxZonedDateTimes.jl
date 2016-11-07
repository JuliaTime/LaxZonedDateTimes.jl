module LaxZonedDateTimes

# Prototype of a new type that is a more context aware Nullable{ZonedDateTime}

using TimeZones
import Base: +, -, .+, .-, ==, show
import Base.Dates: DatePeriod, TimePeriod, TimeType
import TimeZones: utc, localtime, timezone, UTC, Local, interpret

export LaxZonedDateTime

abstract InvalidTimeZone <: TimeZone

immutable NonExistent <: InvalidTimeZone
end

immutable Ambiguous <: InvalidTimeZone
end

# Seems like we want to keep the UTC datetime even if it doesn't align with our local
# datetime so that we can still do UTC based calculations.

immutable LaxZonedDateTime <: TimeType
    local_datetime::DateTime
    timezone::TimeZone
    zone::Union{FixedTimeZone,InvalidTimeZone}
    valid::Bool
end

function LaxZonedDateTime()
    utc = TimeZone("UTC")
    LaxZonedDateTime(DateTime(), utc, utc, false)
end

function LaxZonedDateTime(zdt::ZonedDateTime)
    LaxZonedDateTime(localtime(zdt), timezone(zdt), zdt.zone, true)
end

function LaxZonedDateTime(dt::DateTime, tz::TimeZone, zone)
    LaxZonedDateTime(dt, tz, zone, true)
end

function LaxZonedDateTime(local_dt::DateTime, tz::TimeZone)
    possible = interpret(local_dt, tz, Local)

    num = length(possible)
    if num == 1
        lzdt = LaxZonedDateTime(first(possible))
    elseif num == 0
        lzdt = LaxZonedDateTime(local_dt, tz, NonExistent())
    else
        lzdt = LaxZonedDateTime(local_dt, tz, Ambiguous())
    end

    return lzdt
end

function (==)(x::LaxZonedDateTime, y::LaxZonedDateTime)
    return (
        x.valid == y.valid == false ||
        x.local_datetime == y.local_datetime &&
        x.timezone == y.timezone &&
        x.zone == y.zone &&
        x.valid == y.valid
    )
end

# function LaxZonedDateTime(local_dt::DateTime, tz::VariableTimeZone)
#     possible = interpret(local_dt, tz, Local)

#     num = length(possible)
#     if num == 1
#         return LaxZonedDateTime(first(possible))
#     elseif num == 0
#         before = first(shift_gap(local_dt, tz))
#         return LaxZonedDateTime(local_dt, Nullable{DateTime}(), tz, Nullable(before.zone))
#     else
#         return LaxZonedDateTime(local_dt, Nullable{DateTime}(), tz, Nullable{FixedTimeZone}())
#     end
# end

localtime(lzdt::LaxZonedDateTime) = lzdt.local_datetime
timezone(lzdt::LaxZonedDateTime) = lzdt.timezone
isvalid(lzdt::LaxZonedDateTime) = lzdt.valid

function utc(lzdt::LaxZonedDateTime)
    if !isvalid(lzdt)
        error("Unable to determine UTC datetime from invalid LaxZonedDateTime")
    end

    if isa(lzdt.zone, FixedTimeZone)
        return lzdt.local_datetime - lzdt.zone.offset
    end

    local_dt, tz = localtime(lzdt), timezone(lzdt)
    possible = interpret(local_dt, tz, Local)

    num = length(possible)
    if num == 1
        warn("Internal error")
        return utc(first(possible))
    elseif num == 0
        throw(NonExistentTimeError(local_dt, tz))
    else
        throw(AmbiguousTimeError(local_dt, tz))
    end
end

(-)(x::LaxZonedDateTime, y::LaxZonedDateTime) = utc(x) - utc(y)

function (+)(lzdt::LaxZonedDateTime, p::DatePeriod)
    !isvalid(lzdt) && (return lzdt)

    local_dt, tz = localtime(lzdt), timezone(lzdt)
    local_dt = local_dt + p
    possible = interpret(local_dt, tz, Local)

    num = length(possible)
    if num == 1
        return LaxZonedDateTime(first(possible))
    elseif num == 0
        return LaxZonedDateTime(local_dt, tz, NonExistent())
    else
        return LaxZonedDateTime(local_dt, tz, Ambiguous())
    end
end

function (+)(lzdt::LaxZonedDateTime, p::TimePeriod)
    !isvalid(lzdt) && (return lzdt)

    if isa(lzdt.zone, InvalidTimeZone)
        return LaxZonedDateTime()
    end

    utc_dt, tz = utc(lzdt), timezone(lzdt)
    possible = interpret(utc_dt + p, tz, UTC)
    return LaxZonedDateTime(first(possible))
end

function (-)(lzdt::LaxZonedDateTime, p::DatePeriod)
    return lzdt + (-p)
end

function (-)(lzdt::LaxZonedDateTime, p::TimePeriod)
    return lzdt + (-p)
end


function show(io::IO, lzdt::LaxZonedDateTime)
    if isvalid(lzdt)
        print(io, localtime(lzdt))

        if isa(lzdt.zone, NonExistent)
            print(io, "-DNE")
        elseif isa(lzdt.zone, Ambiguous)
            print(io, "-AMB")
        else
            print(io, lzdt.zone.offset)
        end
    else
        print(io, "NULL")
    end
end

end # module
