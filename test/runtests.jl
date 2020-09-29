using Dates: DateTime
using Dates: DatePeriod, Day, Hour, Millisecond, Minute, Month, Second, Week, Year
using LaxZonedDateTimes
using LaxZonedDateTimes: isrepresentable, NonExistent
using Test
using TimeZones
using TimeZones: Transition, timezone

const winnipeg = TimeZone("America/Winnipeg")

@testset "LaxZonedDateTimes" begin
    include("accessors.jl")
    include("conversions.jl")
    include("intervals.jl")
    include("laxzoneddatetimes.jl")
    include("ranges.jl")
    include("rounding.jl")
end
