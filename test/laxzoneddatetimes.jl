@testset "FixedTimeZone" begin
    utc = TimeZone("UTC")
    fixed = FixedTimeZone("UTC-06:00")
    dt = DateTime(2016, 8, 11, 2, 30)

    for t in (utc, fixed)
        @test ZonedDateTime(LaxZonedDateTime(dt, t)) == ZonedDateTime(dt, t)
        for p in (Hour(1), Day(1))
            @test LaxZonedDateTime(dt, t) + p == LaxZonedDateTime(dt + p, t)
            @test LaxZonedDateTime(dt, t) - p == LaxZonedDateTime(dt - p, t)
        end
    end
end

@testset "VariableTimeZone" begin
    t = VariableTimeZone("Testing", [
        Transition(DateTime(1800,1,1), FixedTimeZone("TST",0,0)),
        Transition(DateTime(1960,4,1,2), FixedTimeZone("TDT",0,7200)),   # 1960-04-01 02:00
        Transition(DateTime(1960,4,1,3), FixedTimeZone("TET",0,10800)),  # 1960-04-01 05:00
        Transition(DateTime(1960,4,1,10), FixedTimeZone("TDT",0,7200)),  # 1960-04-02 12:00
    ])

    @test LaxZonedDateTime(DateTime(1960,3,31,3), t) + Day(1) == LaxZonedDateTime(DateTime(1960,4,1,3), t, NonExistent())

    valid_a = LaxZonedDateTime(DateTime(1960,4,1,1), t)
    valid_b = LaxZonedDateTime(DateTime(1960,4,1,6), t)
    non_existent_a = LaxZonedDateTime(DateTime(1960,4,1,2), t, NonExistent())
    non_existent_b = LaxZonedDateTime(DateTime(1960,4,1,3), t, NonExistent())
    null = LaxZonedDateTime()
    ambiguous = LaxZonedDateTime(DateTime(1960,4,1,12),t)

    @test valid_a + Hour(2) == valid_b
    @test isequal(non_existent_a + Hour(1), null)
    @test isequal(non_existent_b + Hour(1), null)

    @test isequal(non_existent_a + Hour(0), null)
    @test isequal(non_existent_b + Hour(0), null)
    @test isequal(ambiguous + Hour(0), null)

    @test isequal(ambiguous - Hour(1), null)
    @test isequal(ambiguous + Hour(1), null)
end

@testset "non-existent" begin
    lzdt = LaxZonedDateTime(ZonedDateTime(2015,3,7,2, winnipeg))
    lzdt += Day(1)
    @test lzdt == LaxZonedDateTime(DateTime(2015,3,8,2), winnipeg, NonExistent())
    lzdt += Day(1)
    @test lzdt == LaxZonedDateTime(ZonedDateTime(2015,3,9,2,winnipeg))

    non_existent = LaxZonedDateTime(DateTime(2015,3,8,2), winnipeg, NonExistent())
    @test isequal(non_existent + Hour(1), LaxZonedDateTime())
    @test isequal(non_existent - Hour(1), LaxZonedDateTime())
    @test isequal(non_existent + Hour(0), LaxZonedDateTime())
    @test isequal(non_existent - Hour(0), LaxZonedDateTime())

    @test isequal((non_existent + Hour(1)) + Hour(1), LaxZonedDateTime())
    @test isequal((non_existent + Hour(1)) + Day(1), LaxZonedDateTime())  
end

@testset "compare" begin

    @testset "basic" begin
        a = LaxZonedDateTime(ZonedDateTime(2014,winnipeg))
        b = ZonedDateTime(2015,winnipeg)
        @test a < b
    
        a = ZonedDateTime(2016, 11, 6, 1, 30, winnipeg, 1)
        b = ZonedDateTime(2016, 11, 6, 1, winnipeg, 2)

        @test LaxZonedDateTime(a) < b
    end

    @testset "ambiguous" begin
        dt = DateTime(2016, 11, 6, 1, 45)
        amb1 = LaxZonedDateTime(ZonedDateTime(dt, tz"America/Winnipeg", 1))
        amb2 = LaxZonedDateTime(ZonedDateTime(dt, tz"America/Winnipeg", 2))
        amb = LaxZonedDateTime(dt, tz"America/Winnipeg")

        # Note: the fuzzy matching allows ranges to work correctly. Possibly we should
        # use a different operator for this.
        @test amb1 != amb2
        @test amb1 != amb
        @test amb2 != amb

        @test isless(amb1, amb2)
        @test !isless(amb1, amb)
        @test !isless(amb2, amb)

        @test amb1 < amb2
        @test !(amb1 < amb)
        @test !(amb2 < amb)

        @test amb1 <= amb2
        @test amb1 <= amb  # fuzzy
        @test amb2 <= amb  # fuzzy

        @test !(amb1 > amb2)
        @test !(amb1 > amb)
        @test !(amb2 > amb)

        @test !(amb1 >= amb2)
        @test amb1 >= amb  # fuzzy
        @test amb2 >= amb  # fuzzy
    end

    @testset "null equality" begin
        # Unrepresentable LZDTs are treated like NaNs
        null = LaxZonedDateTime()
        @test null != null
        @test isequal(null, null)

        # Test that unrepresentable LZDTs initialized with different values hash the same
        utc = TimeZone("UTC")
        null_2 = LaxZonedDateTime(DateTime(2013, 2, 13, 0, 30), utc, utc, false)
        @test isequal(null, null_2)
        @test hash(null) == hash(null_2)
    end

    @testset "ZonedDateTime" begin
        zdt = ZonedDateTime(DateTime(2016, 11, 10, 1, 45), winnipeg)
        lzdt = LaxZonedDateTime(DateTime(2016, 11, 10, 1, 45), winnipeg)
        dne = LaxZonedDateTime(DateTime(2015, 3, 8, 2), winnipeg)
        nonamb = LaxZonedDateTime(ZonedDateTime(2017, 11, 6, 1, 45, winnipeg, 1))
        amb1 = LaxZonedDateTime(DateTime(2016, 11, 6, 1, 45), winnipeg)
        amb2 = LaxZonedDateTime(DateTime(2017, 11, 5, 1, 45), winnipeg)

        @testset "isequal" begin
            @test isequal(zdt, lzdt)
            @test isequal(lzdt, zdt)
            @test !isequal(zdt, dne)
            @test isequal(dne, dne)
            @test !isequal(amb1, amb2)
            @test isequal(amb1 + Hour(1), amb2 + Hour(1))
            @test !isequal(amb1, nonamb)
        end

        @testset "hash" begin
            @test hash(zdt) == hash(lzdt)
            @test hash(zdt) != hash(dne)
            @test hash(dne) == hash(dne)
            @test hash(amb1) != hash(amb2)
            @test hash(amb1 + Hour(1)) == hash(amb2 + Hour(1))
        end
    end
end