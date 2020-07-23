using BenchmarkTools
using Base.Threads
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
