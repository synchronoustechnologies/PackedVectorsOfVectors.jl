using Documenter
using PackedVectorsOfVectors

DocMeta.setdocmeta!(
    PackedVectorsOfVectors,
    :DocTestSetup,
    quote
        using PackedVectorsOfVectors
        using PackedVectorsOfVectors: cumsum1
    end
)

makedocs(
    modules = PackedVectorsOfVectors,
    sitename="PackedVectorsOfVectors.jl"
)
deploydocs(repo = "github.com/synchronoustechnologies/PackedVectorsOfVectors.jl.git")