using BenchmarkTools

@benchmark sum(rand(1000))

@benchmark sum($(rand(1000)))

#import Pkg
#Pkg.add("FFTW")
using FFTW




#


function profile_test(n)
    for i = 1:n
        A = randn(100,100,20)# 100x100x20 random array
        m = maximum(A)
        Afft = fft(A)
        Am = mapslices(sum, A, dims=2)
        B = A[:,:,5]
        Bsort = mapslices(sort, B, dims=1)
        b = rand(100)
        C = B.*b
    end
end

profile_test(1);  # run once to trigger compilation

#Pkg.add("Profile")
using Profile
Profile.clear()  # in case we have any previous profiling data
@profile profile_test(100)

#Pkg.add("ProfileView")

using ProfileView

ProfileView.view()

ProfileView.view(C=true)



Sys.iswindows()

Sys.iswindows() && run(`wmic cpu`)
#is_linux() && run(`lscpu`)

using Base.Threads

nthreads()

#ENV["JULIA_NUM_THREADS"] = 4

nthreads()

?@threads

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

acc = 0
@threads for i in 1:10_000
    global acc
    acc += 1
end

acc

acc = Atomic{Int64}(0)
@threads for i in 1:10_000
    atomic_add!(acc, 1)
end

acc

function threaded_sum(arr)
   @assert length(arr) % nthreads() == 0
   let results = zeros(eltype(arr), nthreads())
       @threads for tid in 1:nthreads()
           # split work
           acc = zero(eltype(arr))
           len = div(length(arr), nthreads())
           domain = ((tid-1)*len +1):tid*len
           @inbounds for i in domain
               acc += arr[i]
           end
           results[tid] = acc
       end
       sum(results)
   end
end

data = rand(3*2^19);

@btime sum($data)

@btime threaded_sum($data)

function threaded_sum2(arr)
   @assert length(arr) % nthreads() == 0
   let results = zeros(eltype(arr), nthreads())
       @threads for tid in 1:nthreads()
           # split work
           acc = zero(eltype(arr))
           len = div(length(arr), nthreads())
           domain = ((tid-1)*len +1):tid*len
           @inbounds @simd for i in domain
               acc += arr[i]
           end
           results[tid] = acc
       end
       sum(results)
    end
end

@btime threaded_sum2($data)

function myfun(rng::MersenneTwister)
    s = 0.0
    N = 10000
    for i = 1:N
        s += det(randn(rng, 3,3))
    end
    s/N
end


function bench(rgi)
    a = zeros(1000)
    @threads for i = 1:length(a)
        a[i] = myfun(rgi[threadid()])
    end
end

rgi = [MersenneTwister(rand(UInt)) for _ in 1:nthreads()];

@btime bench($rgi)

using StaticArrays

function myfun_fast(rng::MersenneTwister)
    s = 0.0
    N = 10000
    for i in 1:N
        s += det(randn(rng, SMatrix{3, 3}))
    end
    s/N
end

function bench_fast(rgi)
    a = zeros(1000)
    @threads for i in 1:length(a)
        @inbounds a[i] = myfun_fast(rgi[threadid()])
    end
end

rgi_fast = create_rngs();

result = @btime bench_fast($rgi_fast)

addprocs(4)

@everywhere using DistributedArrays
using CuArrays

B = ones(10_000) ./ 2;
A = ones(10_000) .* π;

C = 2 .* A ./ B;
all(C .≈ 4*π)

typeof(C)

dB = distribute(B);
dA = distribute(A);

dC = 2 .* dA ./ dB;
all(dC .≈ 4*π)

typeof(dC)

cuB = CuArray(B);
cuA = CuArray(A);

cuC = 2 .* cuA ./ cuB;
# Disclaimer on Julia v0.6 some operations don't work `sin`. Use CUDAnative.sin instead.
all(cuC .≈ 4*π)

typeof(cuC)

function power_method(M, v)
    for i in 1:100
        v = M*v        # repeatedly creates a new vector and destroys the old v
        v /= norm(v)
    end

    return v, norm(M*v) / norm(v)  # or  (M*v) ./ v
end

M = [2. 1; 1 1]
v = rand(2)

power_method(M, v)

cuM = CuArray(M);
cuv = CuArray(v);

curesult = power_method(cuM, cuv)

typeof(curesult[1])

dM = distribute(M);
dv = distribute(v);

result = power_method(dM, dv)

typeof(result[1])
