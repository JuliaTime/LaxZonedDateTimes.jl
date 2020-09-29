@testset "conversions" begin
    warsaw = tz"Europe/Warsaw"
    zdt = ZonedDateTime(DateTime(2016, 11, 10, 1, 45), winnipeg)
    lzdt = LaxZonedDateTime(DateTime(2016, 11, 10, 1, 45), winnipeg)
    dne = LaxZonedDateTime(DateTime(2015, 3, 8, 2), winnipeg)
    amb = LaxZonedDateTime(DateTime(2016, 11, 6, 1, 45), winnipeg)

    atz_zdt = astimezone(zdt, warsaw)
    atz_lzdt = astimezone(lzdt, warsaw)
    @test atz_zdt == atz_lzdt
    @test timezone(atz_zdt) == timezone(atz_lzdt)
    @test DateTime(lzdt, UTC) == DateTime(atz_lzdt, UTC)

    atz_dne = astimezone(dne, warsaw)
    atz_amb = astimezone(amb, warsaw)
    @test timezone(atz_dne) != warsaw
    @test timezone(atz_amb) != warsaw
    @test !isvalid(atz_dne)
    @test !isvalid(atz_amb)
end
