@testset "ranges" begin
    #=
    If start and/or finish is unrepresentable, the range collects to nothing.
    If start is AMB/DNE, and step is a DatePeriod, it works (start still DNE/AMB)
    If start is AMB/DNE, and step is a TimePeriod, the range collects to nothing.
    If finish is AMB/DNE, and step is a DatePeriod, it works (last element may be
        DNE/AMB)
    If finish is AMB/DNE, and step is a TimePeriod, it works (last element omitted for
        DNE, both specific versions included for AMB)

    When transitions occur between the start and end of a range, they are skipped over
    as per the TimeZones.jl implementation (e.g., when stepping one hour at a time, a
    "spring forward" will result in the range collecting to 0:00, 1:00, 3:00, ...). A
    DNE LaxZonedDateTime will only appear in cases where TimeZones.jl would throw an
    error (e.g., stepping through the "spring forward" transition one day at a time, and
    landing on the missing hour).
    =#

    @testset "basic" begin
        # Default step
        start = LaxZonedDateTime(DateTime(2016, 3, 13, 3, 45), winnipeg)
        finish = LaxZonedDateTime(DateTime(2016, 3, 13, 8, 45), winnipeg)
        @test start:finish == start:Millisecond(1):finish

        # Positive step
        r = start:Hour(1):finish
        @test isa(r, StepRange{LaxZonedDateTime, Hour})
        @test collect(r) == [
            LaxZonedDateTime(DateTime(2016, 3, 13, 3, 45), winnipeg),
            LaxZonedDateTime(DateTime(2016, 3, 13, 4, 45), winnipeg),
            LaxZonedDateTime(DateTime(2016, 3, 13, 5, 45), winnipeg),
            LaxZonedDateTime(DateTime(2016, 3, 13, 6, 45), winnipeg),
            LaxZonedDateTime(DateTime(2016, 3, 13, 7, 45), winnipeg),
            LaxZonedDateTime(DateTime(2016, 3, 13, 8, 45), winnipeg)
        ]
        @test !isempty(r)

        finish = LaxZonedDateTime(DateTime(2016, 3, 18, 3, 45), winnipeg)
        r = start:Day(2):finish
        @test isa(r, StepRange{LaxZonedDateTime, Day})
        @test collect(r) == [
            LaxZonedDateTime(DateTime(2016, 3, 13, 3, 45), winnipeg),
            LaxZonedDateTime(DateTime(2016, 3, 15, 3, 45), winnipeg),
            LaxZonedDateTime(DateTime(2016, 3, 17, 3, 45), winnipeg)
        ]
        @test !isempty(r)

        # Negative step
        start = LaxZonedDateTime(DateTime(2016, 3, 13, 8, 45), winnipeg)
        finish = LaxZonedDateTime(DateTime(2016, 3, 13, 3, 45), winnipeg)
        r = start:Hour(-1):finish
        @test isa(r, StepRange{LaxZonedDateTime, Hour})
        @test collect(r) == [
            LaxZonedDateTime(DateTime(2016, 3, 13, 8, 45), winnipeg),
            LaxZonedDateTime(DateTime(2016, 3, 13, 7, 45), winnipeg),
            LaxZonedDateTime(DateTime(2016, 3, 13, 6, 45), winnipeg),
            LaxZonedDateTime(DateTime(2016, 3, 13, 5, 45), winnipeg),
            LaxZonedDateTime(DateTime(2016, 3, 13, 4, 45), winnipeg),
            LaxZonedDateTime(DateTime(2016, 3, 13, 3, 45), winnipeg)
        ]
        @test !isempty(r)

        start = LaxZonedDateTime(DateTime(2016, 3, 18, 3, 45), winnipeg)
        r = start:Day(-2):finish
        @test isa(r, StepRange{LaxZonedDateTime, Day})
        @test collect(r) == [
            LaxZonedDateTime(DateTime(2016, 3, 18, 3, 45), winnipeg),
            LaxZonedDateTime(DateTime(2016, 3, 16, 3, 45), winnipeg),
            LaxZonedDateTime(DateTime(2016, 3, 14, 3, 45), winnipeg)
        ]
        @test !isempty(r)
    end

    @testset "step through transition" begin
        # step past DNE (hourly)
        start = LaxZonedDateTime(DateTime(2016, 3, 13, 0, 45), winnipeg)
        finish = LaxZonedDateTime(DateTime(2016, 3, 13, 5, 45), winnipeg)
        r = start:Hour(1):finish
        @test isa(r, StepRange{LaxZonedDateTime, Hour})
        @test collect(r) == [
            LaxZonedDateTime(DateTime(2016, 3, 13, 0, 45), winnipeg),
            LaxZonedDateTime(DateTime(2016, 3, 13, 1, 45), winnipeg),
            LaxZonedDateTime(DateTime(2016, 3, 13, 3, 45), winnipeg),   # Skip DNE
            LaxZonedDateTime(DateTime(2016, 3, 13, 4, 45), winnipeg),
            LaxZonedDateTime(DateTime(2016, 3, 13, 5, 45), winnipeg)
        ]
        @test !isempty(r)

        # step past DNE (hourly, backward)
        r = finish:Hour(-1):start
        @test isa(r, StepRange{LaxZonedDateTime, Hour})
        @test collect(r) == [
            LaxZonedDateTime(DateTime(2016, 3, 13, 5, 45), winnipeg),
            LaxZonedDateTime(DateTime(2016, 3, 13, 4, 45), winnipeg),
            LaxZonedDateTime(DateTime(2016, 3, 13, 3, 45), winnipeg),
            LaxZonedDateTime(DateTime(2016, 3, 13, 1, 45), winnipeg),   # Skip DNE
            LaxZonedDateTime(DateTime(2016, 3, 13, 0, 45), winnipeg)
        ]
        @test !isempty(r)

        # step past DNE (daily)
        start = LaxZonedDateTime(DateTime(2016, 3, 11, 2, 45), winnipeg)
        finish = LaxZonedDateTime(DateTime(2016, 3, 16, 2, 45), winnipeg)
        r = start:Day(2):finish
        @test isa(r, StepRange{LaxZonedDateTime, Day})
        @test collect(r) == [
            LaxZonedDateTime(DateTime(2016, 3, 11, 2, 45), winnipeg),
            LaxZonedDateTime(DateTime(2016, 3, 13, 2, 45), winnipeg),   # Include DNE
            LaxZonedDateTime(DateTime(2016, 3, 15, 2, 45), winnipeg)
        ]
        @test !isempty(r)

        # step past DNE (daily, backward)
        start = LaxZonedDateTime(DateTime(2016, 3, 15, 2, 45), winnipeg)
        finish = LaxZonedDateTime(DateTime(2016, 3, 10, 2, 45), winnipeg)
        r = start:Day(-2):finish
        @test isa(r, StepRange{LaxZonedDateTime, Day})
        @test collect(r) == [
            LaxZonedDateTime(DateTime(2016, 3, 15, 2, 45), winnipeg),
            LaxZonedDateTime(DateTime(2016, 3, 13, 2, 45), winnipeg),   # Include DNE
            LaxZonedDateTime(DateTime(2016, 3, 11, 2, 45), winnipeg)
        ]
        @test !isempty(r)

        # step past AMB (hourly)
        start = LaxZonedDateTime(DateTime(2016, 11, 6, 0, 45), winnipeg)
        finish = LaxZonedDateTime(DateTime(2016, 11, 6, 5, 45), winnipeg)
        r = start:Hour(1):finish
        @test isa(r, StepRange{LaxZonedDateTime, Hour})
        @test collect(r) == [
            LaxZonedDateTime(DateTime(2016, 11, 6, 0, 45), winnipeg),
            LaxZonedDateTime(ZonedDateTime(2016, 11, 6, 1, 45, winnipeg, 1)),
            LaxZonedDateTime(ZonedDateTime(2016, 11, 6, 1, 45, winnipeg, 2)),
            LaxZonedDateTime(DateTime(2016, 11, 6, 2, 45), winnipeg),
            LaxZonedDateTime(DateTime(2016, 11, 6, 3, 45), winnipeg),
            LaxZonedDateTime(DateTime(2016, 11, 6, 4, 45), winnipeg),
            LaxZonedDateTime(DateTime(2016, 11, 6, 5, 45), winnipeg)
        ]
        @test !isempty(r)

        # step past AMB (hourly, backward)
        r = finish:Hour(-1):start
        @test isa(r, StepRange{LaxZonedDateTime, Hour})
        @test collect(r) == [
            LaxZonedDateTime(DateTime(2016, 11, 6, 5, 45), winnipeg),
            LaxZonedDateTime(DateTime(2016, 11, 6, 4, 45), winnipeg),
            LaxZonedDateTime(DateTime(2016, 11, 6, 3, 45), winnipeg),
            LaxZonedDateTime(DateTime(2016, 11, 6, 2, 45), winnipeg),
            LaxZonedDateTime(ZonedDateTime(2016, 11, 6, 1, 45, winnipeg, 2)),
            LaxZonedDateTime(ZonedDateTime(2016, 11, 6, 1, 45, winnipeg, 1)),
            LaxZonedDateTime(DateTime(2016, 11, 6, 0, 45), winnipeg)
        ]
        @test !isempty(r)

        # step past AMB (daily)
        start = LaxZonedDateTime(DateTime(2016, 11, 4, 1, 45), winnipeg)
        finish = LaxZonedDateTime(DateTime(2016, 11, 9, 1, 45), winnipeg)
        r = start:Day(2):finish
        @test isa(r, StepRange{LaxZonedDateTime, Day})
        @test collect(r) == [
            LaxZonedDateTime(DateTime(2016, 11, 4, 1, 45), winnipeg),
            LaxZonedDateTime(DateTime(2016, 11, 6, 1, 45), winnipeg),   # Include AMB
            LaxZonedDateTime(DateTime(2016, 11, 8, 1, 45), winnipeg)
        ]
        @test !isempty(r)

        # step past AMB (daily, backward)
        start = LaxZonedDateTime(DateTime(2016, 11, 8, 1, 45), winnipeg)
        finish = LaxZonedDateTime(DateTime(2016, 11, 3, 1, 45), winnipeg)
        r = start:Day(-2):finish
        @test isa(r, StepRange{LaxZonedDateTime, Day})
        @test collect(r) == [
            LaxZonedDateTime(DateTime(2016, 11, 8, 1, 45), winnipeg),
            LaxZonedDateTime(DateTime(2016, 11, 6, 1, 45), winnipeg),   # Include AMB
            LaxZonedDateTime(DateTime(2016, 11, 4, 1, 45), winnipeg)
        ]
        @test !isempty(r)
    end

    @testset "start with unrepresentable" begin
        # start is unrepresentable
        start = LaxZonedDateTime()
        finish = LaxZonedDateTime(DateTime(2016, 3, 13, 8, 45), winnipeg)
        r = start:Hour(1):finish
        @test isa(r, StepRange{LaxZonedDateTime, Hour})
        @test isempty(collect(r))
        @test isempty(r)

        r = start:Hour(-1):finish
        @test isa(r, StepRange{LaxZonedDateTime, Hour})
        @test isempty(collect(r))
        @test isempty(r)

        r = start:Day(2):finish
        @test isa(r, StepRange{LaxZonedDateTime, Day})
        @test isempty(collect(r))
        @test isempty(r)

        r = start:Day(-2):finish
        @test isa(r, StepRange{LaxZonedDateTime, Day})
        @test isempty(collect(r))
        @test isempty(r)

        # start is DNE
        start = LaxZonedDateTime(DateTime(2016, 3, 13, 2, 45), winnipeg)
        finish = LaxZonedDateTime(DateTime(2016, 3, 13, 7, 45), winnipeg)
        r = start:Hour(1):finish
        @test isa(r, StepRange{LaxZonedDateTime, Hour})
        @test isempty(collect(r))
        @test isempty(r)

        start = LaxZonedDateTime(DateTime(2016, 3, 13, 2, 45), winnipeg)
        finish = LaxZonedDateTime(DateTime(2016, 3, 12, 21, 45), winnipeg)
        r = start:Hour(-1):finish
        @test isa(r, StepRange{LaxZonedDateTime, Hour})
        @test isempty(collect(r))
        @test isempty(r)

        start = LaxZonedDateTime(DateTime(2016, 3, 13, 2, 45), winnipeg)
        finish = LaxZonedDateTime(DateTime(2016, 3, 18, 2, 45), winnipeg)
        r = start:Day(2):finish
        @test isa(r, StepRange{LaxZonedDateTime, Day})
        @test collect(r) == [
            LaxZonedDateTime(DateTime(2016, 3, 13, 2, 45), winnipeg),   # Include DNE
            LaxZonedDateTime(DateTime(2016, 3, 15, 2, 45), winnipeg),
            LaxZonedDateTime(DateTime(2016, 3, 17, 2, 45), winnipeg)
        ]
        @test !isempty(r)

        start = LaxZonedDateTime(DateTime(2016, 3, 13, 2, 45), winnipeg)
        finish = LaxZonedDateTime(DateTime(2016, 3, 8, 2, 45), winnipeg)
        r = start:Day(-2):finish
        @test isa(r, StepRange{LaxZonedDateTime, Day})
        @test collect(r) == [
            LaxZonedDateTime(DateTime(2016, 3, 13, 2, 45), winnipeg),   # Include DNE
            LaxZonedDateTime(DateTime(2016, 3, 11, 2, 45), winnipeg),
            LaxZonedDateTime(DateTime(2016, 3, 9, 2, 45), winnipeg)
        ]
        @test !isempty(r)

        # start is AMB
        start = LaxZonedDateTime(DateTime(2016, 11, 6, 1, 45), winnipeg)
        finish = LaxZonedDateTime(DateTime(2016, 11, 6, 6, 45), winnipeg)
        r = start:Hour(1):finish
        @test isa(r, StepRange{LaxZonedDateTime, Hour})
        @test isempty(collect(r))
        @test isempty(r)

        start = LaxZonedDateTime(DateTime(2016, 11, 6, 1, 45), winnipeg)
        finish = LaxZonedDateTime(DateTime(2016, 11, 5, 20, 45), winnipeg)
        r = start:Hour(-1):finish
        @test isa(r, StepRange{LaxZonedDateTime, Hour})
        @test isempty(collect(r))
        @test isempty(r)

        start = LaxZonedDateTime(DateTime(2016, 11, 6, 1, 45), winnipeg)
        finish = LaxZonedDateTime(DateTime(2016, 11, 11, 1, 45), winnipeg)
        r = start:Day(2):finish
        @test isa(r, StepRange{LaxZonedDateTime, Day})
        @test collect(r) == [
            LaxZonedDateTime(DateTime(2016, 11, 6, 1, 45), winnipeg),   # Include AMB
            LaxZonedDateTime(DateTime(2016, 11, 8, 1, 45), winnipeg),
            LaxZonedDateTime(DateTime(2016, 11, 10, 1, 45), winnipeg)
        ]
        @test !isempty(r)

        start = LaxZonedDateTime(DateTime(2016, 11, 6, 1, 45), winnipeg)
        finish = LaxZonedDateTime(DateTime(2016, 11, 1, 1, 45), winnipeg)
        r = start:Day(-2):finish
        @test isa(r, StepRange{LaxZonedDateTime, Day})
        @test collect(r) == [
            LaxZonedDateTime(DateTime(2016, 11, 6, 1, 45), winnipeg),   # Include AMB
            LaxZonedDateTime(DateTime(2016, 11, 4, 1, 45), winnipeg),
            LaxZonedDateTime(DateTime(2016, 11, 2, 1, 45), winnipeg)
        ]
        @test !isempty(r)
    end

    @testset "finish with unrepresentable" begin
        # finish is unrepresentable
        start = LaxZonedDateTime(DateTime(2016, 3, 13, 3, 45), winnipeg)
        finish = LaxZonedDateTime()
        r = start:Hour(1):finish
        @test isa(r, StepRange{LaxZonedDateTime, Hour})
        @test isempty(collect(r))
        @test isempty(r)

        r = start:Hour(-1):finish
        @test isa(r, StepRange{LaxZonedDateTime, Hour})
        @test isempty(collect(r))
        @test isempty(r)

        r = start:Day(2):finish
        @test isa(r, StepRange{LaxZonedDateTime, Day})
        @test isempty(collect(r))
        @test isempty(r)

        r = start:Day(-2):finish
        @test isa(r, StepRange{LaxZonedDateTime, Day})
        @test isempty(collect(r))
        @test isempty(r)

        # finish is DNE
        start = LaxZonedDateTime(DateTime(2016, 3, 12, 21, 45), winnipeg)
        finish = LaxZonedDateTime(DateTime(2016, 3, 13, 2, 45), winnipeg)
        r = start:Hour(1):finish
        @test isa(r, StepRange{LaxZonedDateTime, Hour})
        @test collect(r) == [
            LaxZonedDateTime(DateTime(2016, 3, 12, 21, 45), winnipeg),
            LaxZonedDateTime(DateTime(2016, 3, 12, 22, 45), winnipeg),
            LaxZonedDateTime(DateTime(2016, 3, 12, 23, 45), winnipeg),
            LaxZonedDateTime(DateTime(2016, 3, 13, 0, 45), winnipeg),
            LaxZonedDateTime(DateTime(2016, 3, 13, 1, 45), winnipeg)    # Skip DNE
        ]
        @test !isempty(r)

        start = LaxZonedDateTime(DateTime(2016, 3, 13, 7, 45), winnipeg)
        finish = LaxZonedDateTime(DateTime(2016, 3, 13, 2, 45), winnipeg)
        r = start:Hour(-1):finish
        @test isa(r, StepRange{LaxZonedDateTime, Hour})
        @test collect(r) == [
            LaxZonedDateTime(DateTime(2016, 3, 13, 7, 45), winnipeg),
            LaxZonedDateTime(DateTime(2016, 3, 13, 6, 45), winnipeg),
            LaxZonedDateTime(DateTime(2016, 3, 13, 5, 45), winnipeg),
            LaxZonedDateTime(DateTime(2016, 3, 13, 4, 45), winnipeg),
            LaxZonedDateTime(DateTime(2016, 3, 13, 3, 45), winnipeg)    # Skip DNE
        ]
        @test !isempty(r)

        start = LaxZonedDateTime(DateTime(2016, 3, 9, 2, 45), winnipeg)
        finish = LaxZonedDateTime(DateTime(2016, 3, 13, 2, 45), winnipeg)
        r = start:Day(2):finish
        @test isa(r, StepRange{LaxZonedDateTime, Day})
        @test collect(r) == [
            LaxZonedDateTime(DateTime(2016, 3, 9, 2, 45), winnipeg),
            LaxZonedDateTime(DateTime(2016, 3, 11, 2, 45), winnipeg),
            LaxZonedDateTime(DateTime(2016, 3, 13, 2, 45), winnipeg)    # Include DNE
        ]
        @test !isempty(r)

        start = LaxZonedDateTime(DateTime(2016, 3, 17, 2, 45), winnipeg)
        finish = LaxZonedDateTime(DateTime(2016, 3, 13, 2, 45), winnipeg)
        r = start:Day(-2):finish
        @test isa(r, StepRange{LaxZonedDateTime, Day})
        @test collect(r) == [
            LaxZonedDateTime(DateTime(2016, 3, 17, 2, 45), winnipeg),
            LaxZonedDateTime(DateTime(2016, 3, 15, 2, 45), winnipeg),
            LaxZonedDateTime(DateTime(2016, 3, 13, 2, 45), winnipeg)    # Include DNE
        ]
        @test !isempty(r)

        # finish is AMB
        start = LaxZonedDateTime(DateTime(2016, 11, 5, 20, 45), winnipeg)
        finish = LaxZonedDateTime(DateTime(2016, 11, 6, 1, 45), winnipeg)
        r = start:Hour(1):finish
        @test isa(r, StepRange{LaxZonedDateTime, Hour})
        @test collect(r) == [
            LaxZonedDateTime(DateTime(2016, 11, 5, 20, 45), winnipeg),
            LaxZonedDateTime(DateTime(2016, 11, 5, 21, 45), winnipeg),
            LaxZonedDateTime(DateTime(2016, 11, 5, 22, 45), winnipeg),
            LaxZonedDateTime(DateTime(2016, 11, 5, 23, 45), winnipeg),
            LaxZonedDateTime(DateTime(2016, 11, 6, 0, 45), winnipeg),
            LaxZonedDateTime(ZonedDateTime(2016, 11, 6, 1, 45, winnipeg, 1)),
            LaxZonedDateTime(ZonedDateTime(2016, 11, 6, 1, 45, winnipeg, 2))
        ]
        @test !isempty(r)

        start = LaxZonedDateTime(DateTime(2016, 11, 6, 6, 45), winnipeg)
        finish = LaxZonedDateTime(DateTime(2016, 11, 6, 1, 45), winnipeg)
        r = start:Hour(-1):finish
        @test isa(r, StepRange{LaxZonedDateTime, Hour})
        @test collect(r) == [
            LaxZonedDateTime(DateTime(2016, 11, 6, 6, 45), winnipeg),
            LaxZonedDateTime(DateTime(2016, 11, 6, 5, 45), winnipeg),
            LaxZonedDateTime(DateTime(2016, 11, 6, 4, 45), winnipeg),
            LaxZonedDateTime(DateTime(2016, 11, 6, 3, 45), winnipeg),
            LaxZonedDateTime(DateTime(2016, 11, 6, 2, 45), winnipeg),
            LaxZonedDateTime(ZonedDateTime(2016, 11, 6, 1, 45, winnipeg, 2)),
            LaxZonedDateTime(ZonedDateTime(2016, 11, 6, 1, 45, winnipeg, 1))
        ]
        @test !isempty(r)

        start = LaxZonedDateTime(DateTime(2016, 11, 2, 1, 45), winnipeg)
        finish = LaxZonedDateTime(DateTime(2016, 11, 6, 1, 45), winnipeg)
        r = start:Day(2):finish
        @test isa(r, StepRange{LaxZonedDateTime, Day})
        @test collect(r) == [
            LaxZonedDateTime(DateTime(2016, 11, 2, 1, 45), winnipeg),
            LaxZonedDateTime(DateTime(2016, 11, 4, 1, 45), winnipeg),
            LaxZonedDateTime(DateTime(2016, 11, 6, 1, 45), winnipeg)    # Include AMB
        ]
        @test !isempty(r)

        start = LaxZonedDateTime(DateTime(2016, 11, 10, 1, 45), winnipeg)
        finish = LaxZonedDateTime(DateTime(2016, 11, 6, 1, 45), winnipeg)
        r = start:Day(-2):finish
        @test isa(r, StepRange{LaxZonedDateTime, Day})
        @test collect(r) == [
            LaxZonedDateTime(DateTime(2016, 11, 10, 1, 45), winnipeg),
            LaxZonedDateTime(DateTime(2016, 11, 8, 1, 45), winnipeg),
            LaxZonedDateTime(DateTime(2016, 11, 6, 1, 45), winnipeg)    # Include AMB
        ]
        @test !isempty(r)
    end
end