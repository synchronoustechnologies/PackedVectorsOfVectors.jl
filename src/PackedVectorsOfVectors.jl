module PackedVectorsOfVectors

export
    PackedVectorOfVectors,
    pack,
    allocate_packed,
    packed_indices


"""
    PackedVectorOfVectors{P,V,E} <: AbstractVector{E}

Vector of vectors, stored as a single long vector `v::V` and a vector of
pointers `p::P` indicating the subvector boundaries.

`PackedVectorOfVectors` is roughly equivalent to `SparseMatrixCSC` without the
`rowval` vector.
"""
struct PackedVectorOfVectors{P,V,E} <: AbstractVector{E}
    p::P
    v::V
end

PackedVectorOfVectors(p,v) = PackedVectorOfVectors{typeof(p),typeof(v),typeof(view(v,1:0))}(p,v)

Base.size(pv::PackedVectorOfVectors) = (length(pv.p)-1,)
Base.getindex(pv::PackedVectorOfVectors, i::Int) = view(pv.v, pv.p[i]:pv.p[i+1]-1)
Base.showarg(io::IO, pv::PackedVectorOfVectors, toplevel) = print(io, "pack(::Vector{Vector{", eltype(eltype(pv)), "}})")


"""
    cumsum1(v) -> p

Cumulative sum of the iterable `v`, starting from `p[1] = 1`.

# Examples
```jldoctest
julia> cumsum1([2,1,3])
4-element Vector{Int64}:
 1
 3
 4
 7
```
"""
cumsum1(v) = cumsum1!(Vector{Int}(undef,length(v)+1), v)


"""
    cumsum1!(p,v) -> p

Same as `cumsum1(v)`, but using the preallocated vector `p`.
"""
function cumsum1!(p,v)
    @assert length(p) == length(v)+1  "Mismatched lengths of p and v in cumsum1!(p,v)"
    s = 1
    p[1] = s
    @inbounds for (k,vk) in enumerate(v)
        s += vk
        p[k+1] = s
    end
    return p
end


"""
    pack([T,] vv) -> PackedVectorOfVectors

Convert the vector of vectors `vv` to its packed representation. If `T` is
provided, then the elements of the nested vector are converted to this type.

# Example
```jldoctest
julia> pack([[1,2],[3]])
2-element pack(::Vector{Vector{Int64}}):
 [1, 2]
 [3]

julia> pack(Float64, [[1,2],[3]])
2-element pack(::Vector{Vector{Float64}}):
 [1.0, 2.0]
 [3.0]
```
"""
pack(vv) = pack(eltype(eltype(vv)),vv)
function pack(T::Type, vv)
    p = cumsum1(length(v) for v in vv)
    v = Vector{T}(undef, p[end]-1)
    pv = PackedVectorOfVectors(p,v)
    for (k,vk) in enumerate(vv)
        pv[k] .= vk
    end
    return pv
end


"""
    allocate_packed(T, init, n) -> PackedVectorOfVectors

Allocate a packed vector of vectors with nested element type `T` such that the
`k`th nested vector has length `nth(n,k)`. See the documentation of
`Vector{T}(init,n)` regarding the meaning of `init`.

# Examples
```jldoctest
julia> allocate_packed(Ref{Int}, undef, [1,2,3])
3-element pack(::Vector{Vector{Ref{Int64}}}):
 [#undef]
 [#undef, #undef]
 [#undef, #undef, #undef]
```
"""
function allocate_packed(T::Type, init, n)
    p = cumsum1(n)
    v = Vector{T}(init, p[end]-1)
    return PackedVectorOfVectors(p,v)
end


"""
    packed_indices(n) -> pv::PackedVectorOfVectors

Packed vector of vectors such that the `k`th nested vector has length `nth(n,k)`
and `pv[k][i]` is the index in the flattened vector of the `i`th element in the
`k`th nested vector.

# Examples
```jldoctest
julia> packed_indices([2,3])
2-element pack(::Vector{Vector{Int64}}):
 1:2
 3:5
```
"""
function packed_indices(n)
    p = cumsum1(n)
    v = 1:p[end]-1
    return PackedVectorOfVectors(p,v)
end


"""
    transpose(pv::PackedVectorOfVectors[, n = maximum(maximum.(pv))) -> PackedVectorOfVectors

Interpret `pv` as the sparsity pattern of a sparse matrix and compute the
sparsity pattern of its transpose.

The nested eltype of `pv` must be `Int`.

# Examples
```jldoctest
julia> transpose(pack([[1,2],[2]]))
2-element pack(::Vector{Vector{Int64}}):
 [1]
 [1, 2]
```
"""
function Base.transpose(
    pv::PackedVectorOfVectors,
    n = maximum(pv.v; init=0)
)
    @assert eltype(eltype(pv)) == Int  "transpose(pv::PackedVectorOfVectors) is defined only if the nested eltype is Int"
    p,v = pv.p,pv.v

    # Compute row counts
    q = zeros(Int,n+1)
    for vk in v
        q[vk+1] += 1
    end

    # Set up q so q[k+1] points to beginning of column k in w
    q[1] = 1
    s = 1
    @inbounds for k = 2:n+1
        t = q[k]
        q[k] = s
        s += t
    end

    # Copy v into w and simultaneously finalise q
    w = Vector{Int}(undef, length(v))
    @inbounds for i = 1:length(pv)
        for j = pv[i]
            w[q[j+1]] = i
            q[j+1] += 1
        end
    end

    return PackedVectorOfVectors(q,w)
end

end # module
