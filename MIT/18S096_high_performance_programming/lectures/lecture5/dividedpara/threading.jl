using Base.Threads
#using Random
using Random: GLOBAL_RNG
nthreads()

#ENV["JULIA_NUM_THREADS"] = 4

nthreads()



function rand_init1(A)
    @threads for i in 1:length(A)
        A[i] = rand()
    end
end

function rand_init2(rngs, A)
    @threads for i in 1:length(A)
        A[i] = rand(rngs[threadid()])
    end
end

# Based on https://github.com/bkamins/KissThreading.jl/blob/8675f55ef9469fccf808a44237bd5f0bbb02b950/src/KissThreading.jl#L5-L15
function create_rngs()
    rngjmp = randjump(Base.GLOBAL_RNG, nthreads()+1)
    rngs = Vector{MersenneTwister}(nthreads())
    Threads.@threads for tid in 1:nthreads()
        rngs[tid] = deepcopy(rngjmp[tid+1])
    end
    all([isassigned(rngs, i) for i in 1:nthreads()]) || error("failed to create rngs")
    return rngs
end

basic_rngs = [MersenneTwister(rand(UInt64)) for i in 1:nthreads()]
proper_rngs = create_rngs();

A = zeros(10_000);

@benchmark rand_init1($A)

@benchmark rand_init2($basic_rngs, $A)

@benchmark rand_init2($proper_rngs, $A)
