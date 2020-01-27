module LaxZonedDateTimes

# Prototype of a new type that is a more context aware Nullable{ZonedDateTime}

using Dates: AbstractDateTime, DatePeriod, DateTime, Dates, Millisecond, Period, TimePeriod
using Intervals
using TimeZones
using TimeZones: Local, UTC, interpret, timezone

export
    LaxZonedDateTime, ZDT,
    # accessors.jl
    isvalid, isinvalid, isambiguous, isnonexistent,
    hour, minute, second, millisecond

abstract type InvalidTimeZone <: TimeZone end

struct NonExistent <: InvalidTimeZone end

struct Ambiguous <: InvalidTimeZone end

# Seems like we want to keep the UTC datetime even if it doesn't align with our local
# datetime so that we can still do UTC based calculations.

struct LaxZonedDateTime <: AbstractDateTime
    local_datetime::DateTime
    timezone::TimeZone
    zone::Union{FixedTimeZone,InvalidTimeZone}
    representable::Bool

    function LaxZonedDateTime(dt, tz, zone, rep)
        utc = TimeZone("UTC")
        return rep ? new(dt, tz, zone, rep) : new(DateTime(0), utc, utc, false)
    end
end

function LaxZonedDateTime()
    utc = TimeZone("UTC")
    LaxZonedDateTime(DateTime(0), utc, utc, false)
end

function LaxZonedDateTime(zdt::ZonedDateTime)
    LaxZonedDateTime(DateTime(zdt, Local), timezone(zdt), zdt.zone, true)
end

function LaxZonedDateTime(dt::DateTime, tz::TimeZone, zone)
    LaxZonedDateTime(dt, tz, zone, true)
end

function LaxZonedDateTime(local_dt::DateTime, tz::FixedTimeZone)
    return LaxZonedDateTime(ZonedDateTime(local_dt, tz))
end

function LaxZonedDateTime(local_dt::DateTime, tz::VariableTimeZone)
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

# We need to define the behaviour for constructing an empty Interval of LaxZonedDateTimes
function Intervals.Interval{T}() where T <: LaxZonedDateTime
    return Interval{T}(
        T(DateTime(0), tz"UTC"),
        T(DateTime(0), tz"UTC"),
        Inclusivity(false, false)
    )
end

function Base.:(==)(x::LaxZonedDateTime, y::LaxZonedDateTime)
    if isvalid(x) && isvalid(y)
        return DateTime(x, UTC) == DateTime(y, UTC)
    else
        return (
            x.representable == y.representable == true &&
            x.local_datetime == y.local_datetime &&
            x.timezone == y.timezone &&
            x.zone == y.zone
        )
    end
end

function Base.:(==)(x::LaxZonedDateTime, y::ZonedDateTime)
    if isvalid(x)
        return DateTime(x, UTC) == DateTime(y, UTC)
    else
        return false
    end
end

Base.:(==)(x::ZonedDateTime, y::LaxZonedDateTime) = y == x

# Note: `hash` and `isequal` assume that the "zone" of a ZonedDateTime is not being set
# incorrectly.

function Base.isequal(x::LaxZonedDateTime, y::LaxZonedDateTime)
    if isvalid(x) && isvalid(y)
        return isequal(DateTime(x, UTC), DateTime(y, UTC))
    else
        return (
            isequal(x.local_datetime, y.local_datetime) &&
            isequal(x.timezone, y.timezone) &&
            isequal(x.zone, y.zone) &&
            isequal(x.representable, y.representable)
        )
    end
end

function Base.isequal(x::LaxZonedDateTime, y::ZonedDateTime)
    isvalid(x) ? isequal(DateTime(x, UTC), DateTime(y, UTC)) : false
end

Base.isequal(x::ZonedDateTime, y::LaxZonedDateTime) = isequal(y, x)

# Valid LaxZonedDateTimes should hash to the same value as the equivalent ZonedDateTime
# All invalid or unrepresentable LaxZonedDateTimes should always hash to a different value.
function Base.hash(lzdt::LaxZonedDateTime, h::UInt)
    if isvalid(lzdt)
        h = hash(:utc_instant, h)
        h = hash(DateTime(lzdt, UTC), h)
    else
        h = hash(:invalid_utc_instant, h)
        h = hash(lzdt.local_datetime, h)
    end

    return h
end

function Base.:(-)(x::LaxZonedDateTime, y::LaxZonedDateTime)
    if isvalid(x) && isvalid(y)
        DateTime(x, UTC) - DateTime(y, UTC)
    else
        nothing
    end
end

function Base.:(-)(x::LaxZonedDateTime, y::ZonedDateTime)
    if isvalid(x)
        DateTime(x, UTC) - DateTime(y, UTC)
    else
        nothing
    end
end

Base.:(-)(x::ZonedDateTime, y::LaxZonedDateTime) = y - x

function Base.:(+)(lzdt::LaxZonedDateTime, p::DatePeriod)
    !isrepresentable(lzdt) && (return lzdt)
    isa(lzdt.timezone, FixedTimeZone) && (return LaxZonedDateTime(ZonedDateTime(lzdt) + p))

    local_dt, tz = DateTime(lzdt, Local), timezone(lzdt)
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

function Base.:(+)(lzdt::LaxZonedDateTime, p::TimePeriod)
    !isrepresentable(lzdt) && (return lzdt)
    isa(lzdt.timezone, FixedTimeZone) && (return LaxZonedDateTime(ZonedDateTime(lzdt) + p))
    isa(lzdt.zone, InvalidTimeZone) && (return LaxZonedDateTime())

    utc_dt, tz = DateTime(lzdt, UTC), timezone(lzdt)
    possible = interpret(utc_dt + p, tz, UTC)
    return LaxZonedDateTime(first(possible))
end

function Base.:(-)(lzdt::LaxZonedDateTime, p::Period)
    return lzdt + (-p)
end

function Base.show(io::IO, lzdt::LaxZonedDateTime)
    if isrepresentable(lzdt)
        print(io, DateTime(lzdt, Local))

        if isa(lzdt.zone, NonExistent)
            print(io, "-DNE")
        elseif isa(lzdt.zone, Ambiguous)
            print(io, "-AMB")
        else
            print(io, lzdt.zone.offset)
        end
    else
        print(io, "unrepresentable")
    end
end

Base.promote_rule(::Type{LaxZonedDateTime},::Type{ZonedDateTime}) = LaxZonedDateTime
Base.convert(::Type{LaxZonedDateTime}, x::ZonedDateTime) = LaxZonedDateTime(x)
Base.convert(::Type{ZonedDateTime}, x::LaxZonedDateTime) = ZonedDateTime(x)

function Base.isless(a::LaxZonedDateTime, b::LaxZonedDateTime)
    if !isrepresentable(a) || !isrepresentable(b)
        return false
    end

    # Need to compare using UTC when the zones are fixed and don't have the same offset.
    if a.zone != b.zone && isa(a.zone, FixedTimeZone) && isa(b.zone, FixedTimeZone)
        return isless(DateTime(a, UTC), DateTime(b, UTC))
    else
        return isless(DateTime(a, Local), DateTime(b, Local))
    end
end

Base.:(<=)(a::LaxZonedDateTime, b::LaxZonedDateTime) = !(a > b)

function TimeZones.ZonedDateTime(lzdt::LaxZonedDateTime, ambiguous::Symbol=:throw)
    if !isrepresentable(lzdt)
        throw(ArgumentError("Unable to determine UTC datetime from an unrepresentable LaxZonedDateTime"))
    end

    if isa(lzdt.zone, FixedTimeZone)
        utc_dt = lzdt.local_datetime - lzdt.zone.offset
        return ZonedDateTime(utc_dt, timezone(lzdt); from_utc=true)
    end

    local_dt, tz = DateTime(lzdt, Local), timezone(lzdt)
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

const ZDT = Union{ZonedDateTime, LaxZonedDateTime}

include("accessors.jl")
include("conversions.jl")
include("rounding.jl")
include("ranges.jl")
include("deprecated.jl")

end
