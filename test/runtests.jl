using Test
using PackedVectorsOfVectors

using Documenter
DocMeta.setdocmeta!(
    PackedVectorsOfVectors,
    :DocTestSetup,
    quote
        using PackedVectorsOfVectors
        using PackedVectorsOfVectors: cumsum1
    end
)
doctest(PackedVectorsOfVectors, testset="docs")

@testset "pack" begin
    pv = pack([[1,2],[3]])
    @test pv.p == [1,3,4]
    @test pv.v == [1,2,3]

    pv = pack([])
    @test pv.p == [1]
    @test pv.v == []

    pv = pack([[]])
    @test pv.p == [1,1]
    @test pv.v == []

    pv = pack([[],[]])
    @test pv.p == [1,1,1]
    @test pv.v == []

    pv = pack([[1],[]])
    @test pv.p == [1,2,2]
    @test pv.v == [1]

    pv = pack([[],[1]])
    @test pv.p == [1,1,2]
    @test pv.v == [1]
end

@testset "allocate_packed" begin
    pv = allocate_packed(Int, undef, [1,2,3])
    @test pv.p == [1,2,4,7]
    @test length(pv.v) == 6
end

@testset "vector interface" begin
    vv = [[1,2],[3]]
    @test collect(pack(vv)) == vv
end

@testset "transpose" begin
    @test collect(transpose(pack([[1,2],[1]]))) == pack([[1,2],[1]])
    @test collect(transpose(pack([[1,2],[2]]))) == pack([[1],[1,2]])
    @test collect(transpose(pack([[1,2],[3]]))) == pack([[1],[1],[2]])

    @test collect(transpose(pack(Vector{Int}[]))) == pack([])
    @test collect(transpose(pack(Vector{Int}[[]]))) == pack([])
    @test collect(transpose(pack(Vector{Int}[[1],[]]))) == pack([[1]])
    @test collect(transpose(pack(Vector{Int}[[],[2]]))) == pack([[],[2]])
end
