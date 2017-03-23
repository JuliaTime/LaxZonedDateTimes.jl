module LaxZonedDateTimes

# Prototype of a new type that is a more context aware Nullable{ZonedDateTime}

using TimeZones
import Base: +, -, .+, .-, ==, isequal, show
import Base.Dates: DatePeriod, TimePeriod, TimeType, Millisecond
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

    function LaxZonedDateTime(dt, tz, zone, rep)
        utc = TimeZone("UTC")
        return rep ? new(dt, tz, zone, rep) : new(DateTime(), utc, utc, false)
    end
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
        x.representable == y.representable == true &&
        x.local_datetime == y.local_datetime &&
        x.timezone == y.timezone &&
        x.zone == y.zone
    )
end

function isequal(x::LaxZonedDateTime, y::LaxZonedDateTime)
    return hash(x) == hash(y)
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
include("rounding.jl")
include("ranges.jl")


function (-)(x::LaxZonedDateTime, y::LaxZonedDateTime)
    R = Nullable{Millisecond}
    return (isvalid(x) && isvalid(y)) ? R(utc(x) - utc(y)) : R()
end
function (-)(x::LaxZonedDateTime, y::ZonedDateTime)
    R = Nullable{Millisecond}
    return isvalid(x) ? R(utc(x) - utc(y)) : R()
end
(-)(x::ZonedDateTime, y::LaxZonedDateTime) = y - x

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

function (-)(lzdt::LaxZonedDateTime, p::Period)
    return lzdt + (-p)
end

# Allow a Nullable{Period} to be subtracted from an LZDT. (This is necessary because
# subtracting one LZDT from another returns a Nullable, and StepRange constructor code makes
# use of the result in a further subtraction. This prevents us from having to rewrite all of
# the range code.)
function (-){P<:Period}(lzdt::LaxZonedDateTime, p::Nullable{P})
    return isnull(p) ? LaxZonedDateTime() : lzdt - get(p)
end

function (+){P<:Period}(lzdt::LaxZonedDateTime, p::Nullable{P})
    return isnull(p) ? LaxZonedDateTime() : lzdt + get(p)
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
        print(io, "INVALID")
    end
end

Base.promote_rule(::Type{LaxZonedDateTime},::Type{ZonedDateTime}) = LaxZonedDateTime
Base.convert(::Type{LaxZonedDateTime}, x::ZonedDateTime) = LaxZonedDateTime(x)
Base.convert(::Type{ZonedDateTime}, x::LaxZonedDateTime) = ZonedDateTime(x)

function Base.isless(a::LaxZonedDateTime, b::LaxZonedDateTime)
    if !isrepresentable(a) || !isrepresentable(b)
        return false
    end

    # Need to compare using UTC  when the zones are fixed and don't have the same offset.
    if a.zone != b.zone && isa(a.zone, FixedTimeZone) && isa(b.zone, FixedTimeZone)
        return utc(a) < utc(b)
    else
        return localtime(a) < localtime(b)
    end
end

function ZonedDateTime(lzdt::LaxZonedDateTime, ambiguous::Symbol=:invalid)
    if !isrepresentable(lzdt)
        throw(ArgumentError("Unable to determine UTC datetime from an unrepresentable LaxZonedDateTime"))
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

end  # module
