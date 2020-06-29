using Base: steprange_last, steprange_last_empty
using Dates: guess, len, Millisecond

function Base.:(:)(start::LaxZonedDateTime, stop::LaxZonedDateTime)
    return StepRange(start, Millisecond(1), stop)
end

"""
    guess(start::LaxZonedDateTime, finish::LaxZonedDateTime, step) -> Integer

Given a start and end date, indicates how many steps/periods are between them. Defining this
function allows `StepRange`s to be defined for `LaxZonedDateTime`s. (For non-empty
`StepRange`s, `guess` will ideally return one less than the number of elements.)
"""
function Dates.guess(start::LaxZonedDateTime, finish::LaxZonedDateTime, step)
    if isvalid(start) && isvalid(finish)
        return guess(DateTime(start, UTC), DateTime(finish, UTC), step)
    else
        return 0    # Can't easily guess. It will be calculated with len instead.
    end
end

function Dates.len(start::LaxZonedDateTime, finish::LaxZonedDateTime, step)
    !(isrepresentable(start) && isrepresentable(finish)) && return 0

    # Because of the way unrepresentable LZDTs can propagate, we need to start counting from
    # start, instead of starting from min(start, finish) and incrementing by abs(step).
    compare = (step > zero(step)) ? (<=) : (>=)

    i = guess(start, finish, step) - 1
    while isrepresentable(start + step * i) && compare(start + step * i, finish)
        i += 1
    end
    return i - 1
end

function Base.steprange_last(start::LaxZonedDateTime, step, stop::LaxZonedDateTime)
    z = zero(step)
    step == z && throw(ArgumentError("step cannot be zero"))

    if (stop == start) || !stop.representable
        last = stop
    else
        if (step > z) != (stop > start)
            last = steprange_last_empty(start, step, stop)
        else
            last = start + step * len(start, stop, step)
        end
    end
    return last
end

function Base.isempty(r::StepRange{LaxZonedDateTime})
    return !(isrepresentable(r.start) && isrepresentable(r.stop)) || (
        (r.start != r.stop) & ((r.step > zero(r.step)) != (r.stop > r.start))
    )
end

##### Support for StepRange{AnchoredInterval{LaxZonedDateTime}} #####
# Ideally this would go in Intervals.jl, but it goes here because it doesn't make sense to
# reference a private package (this one) in a public package (Intervals.jl)

function Dates.guess(
    start::AnchoredInterval{P, LaxZonedDateTime},
    finish::AnchoredInterval{P, LaxZonedDateTime},
    step
) where P
    return guess(anchor(start), anchor(finish), step)
end

function Dates.len(
    start::AnchoredInterval{P, LaxZonedDateTime},
    finish::AnchoredInterval{P, LaxZonedDateTime},
    step
) where P
    return len(anchor(start), anchor(finish), step)
end

function Base.steprange_last(
    start::AnchoredInterval{P, LaxZonedDateTime},
    step,
    stop::AnchoredInterval{P, LaxZonedDateTime},
) where P
    return AnchoredInterval{P}(steprange_last(anchor(start), step, anchor(stop)))
end

function Base.isempty(r::StepRange{A}) where A <: AnchoredInterval{P, LaxZonedDateTime} where P
    a_start, a_stop, step = anchor(r.start), anchor(r.stop), r.step
    return !(isrepresentable(a_start) && isrepresentable(a_stop)) || (
        (a_start != a_stop) & ((step > zero(step)) != (a_stop > a_start))
    )
end
