module LaxZonedDateTimes

# Prototype of a new type that is a more context aware Nullable{ZonedDateTime}

using TimeZones
import Base: +, -, .+, .-, ==, show
import Base.Dates: DatePeriod, TimePeriod, TimeType
import TimeZones: ZonedDateTime, utc, localtime, timezone, UTC, Local, interpret

export LaxZonedDateTime,
    # accessors.jl
    isvalid, isambiguous, isnonexistent,
    hour, minute, second, millisecond

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
    representable::Bool
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
        x.representable == y.representable == false ||
        x.local_datetime == y.local_datetime &&
        x.timezone == y.timezone &&
        x.zone == y.zone &&
        x.representable == y.representable
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

include("accessors.jl")


(-)(x::LaxZonedDateTime, y::LaxZonedDateTime) = utc(x) - utc(y)
(-)(x::LaxZonedDateTime, y::ZonedDateTime) = utc(x) - utc(y)
(-)(x::ZonedDateTime, y::LaxZonedDateTime) = utc(x) - utc(y)

(.-)(x::AbstractArray{LaxZonedDateTime}, y::ZonedDateTime) = x .- LaxZonedDateTime(y)
function (.-)(x::AbstractArray{ZonedDateTime}, y::LaxZonedDateTime)
    x .- ZonedDateTime(utc(y), timezone(y); from_utc=true)
end

function (+)(lzdt::LaxZonedDateTime, p::DatePeriod)
    !isrepresentable(lzdt) && (return lzdt)

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
    !isrepresentable(lzdt) && (return lzdt)

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
    if isrepresentable(lzdt)
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

Base.promote_rule(::Type{LaxZonedDateTime},::Type{ZonedDateTime}) = LaxZonedDateTime
Base.convert(::Type{LaxZonedDateTime}, x::ZonedDateTime) = LaxZonedDateTime(x)
Base.convert(::Type{ZonedDateTime}, x::LaxZonedDateTime) = ZonedDateTime(x)

function Base.isless(a::LaxZonedDateTime, b::LaxZonedDateTime)
    if !isrepresentable(a) || !isrepresentable(b)
        return false
    end

    a_local_dt, b_local_dt = localtime(a), localtime(b)
    if a_local_dt == b_local_dt && isa(a.zone, FixedTimeZone) && isa(b.zone, FixedTimeZone)
        return utc(a) < utc(b)
    else
        return a_local_dt < b_local_dt
    end
end

function ZonedDateTime(lzdt::LaxZonedDateTime, ambiguous::Symbol=:invalid)
    if !isrepresentable(lzdt)
        error("Unable to determine UTC datetime from an unrepresentable LaxZonedDateTime")
    end

    if isa(lzdt.zone, FixedTimeZone)
        utc_dt = lzdt.local_datetime - lzdt.zone.offset
        return ZonedDateTime(utc_dt, timezone(lzdt); from_utc=true)
    end

    local_dt, tz = localtime(lzdt), timezone(lzdt)
    possible = interpret(local_dt, tz, Local)

    num = length(possible)
    if num == 1
        return first(possible)
    elseif num == 0
        throw(NonExistentTimeError(local_dt, tz))
    else
        if ambiguous == :first
            return first(possible)
        elseif ambiguous == :last
            return last(possible)
        else
            throw(AmbiguousTimeError(local_dt, tz))
        end
    end
end

end # module
