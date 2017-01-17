import Base.Dates: guess, len
import Base: steprange_last, steprange_last_empty

"""
    guess(start::LaxZonedDateTime, finish::LaxZonedDateTime, step) -> Integer

Given a start and end date, indicates how many steps/periods are between them. Defining this
function allows `StepRange`s to be defined for `LaxZonedDateTime`s. (For non-empty
`StepRange`s, `guess` will ideally return one less than the number of elements.)
"""
function guess(start::LaxZonedDateTime, finish::LaxZonedDateTime, step)
    isvalid(start) && isvalid(finish) && return guess(utc(start), utc(finish), step)
    return 0    # Can't easily guess. Do the work to calculate it instead.
end

function len(start::LaxZonedDateTime, finish::LaxZonedDateTime, step)
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

function steprange_last(start::LaxZonedDateTime, step, stop::LaxZonedDateTime)
    z = zero(step)
    step == z && throw(ArgumentError("step cannot be zero"))

    if stop == start
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
