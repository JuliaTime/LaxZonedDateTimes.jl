@testset "accessors" begin

    amb = LaxZonedDateTime(DateTime(2015,11,1,1),winnipeg)
    amb_first = LaxZonedDateTime(ZonedDateTime(2015,11,1,1,winnipeg,1))
    amb_last = LaxZonedDateTime(ZonedDateTime(2015,11,1,1,winnipeg,2))

    @test amb_first < amb_last
    @test !(amb_first < amb)
    @test !(amb < amb_first)
    @test !(amb_last < amb)
    @test !(amb < amb_last)

    non_existent = LaxZonedDateTime(DateTime(2015,3,8,2),winnipeg)
    @test ZonedDateTime(2015,3,8,1,winnipeg) < non_existent < ZonedDateTime(2015,3,8,3,winnipeg)


    @test hour(amb) == hour(amb_first) == hour(amb_last) == 1
    @test hour(non_existent) == 2

    @test month(amb) == 11

    null = LaxZonedDateTime()
    @test_throws Exception DateTime(null)
    @test_throws Exception DateTime(null, UTC)
    @test_throws Exception hour(null)


    @test !isvalid(null)
    @test !isvalid(amb)
    @test isvalid(amb_first)
    @test isvalid(amb_last)
    @test !isvalid(non_existent)

    @test !isinvalid(null)
    @test isinvalid(amb)
    @test !isinvalid(amb_first)
    @test !isinvalid(amb_last)
    @test isinvalid(non_existent)

    @test !isrepresentable(null)
    @test isrepresentable(amb)
    @test isrepresentable(amb_first)
    @test isrepresentable(amb_last)
    @test isrepresentable(non_existent)

    @test !isambiguous(null)
    @test isambiguous(amb)
    @test !isambiguous(amb_first)
    @test !isambiguous(amb_last)
    @test !isambiguous(non_existent)

    @test !isnonexistent(null)
    @test !isnonexistent(amb)
    @test !isnonexistent(amb_first)
    @test !isnonexistent(amb_last)
    @test isnonexistent(non_existent)

    @test amb_last - amb_first == Hour(1)
    @test amb - amb_first === nothing
    @test non_existent - amb_first === nothing
    @test null - amb_first === nothing


end
