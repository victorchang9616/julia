"""
function threaded_sum(arr) ## for nthreads=6
   #@assert length(arr) % nthreads() == 0 ## should be no effect
   let results = zeros(eltype(arr), nthreads())
       @threads for tid in 1:nthreads() # tid := task id
           # split work
           acc = zero(eltype(arr)) # local accumulator
           len = div(length(arr), nthreads()) # len for each subjob for a thread
           domain = ((tid-1)*len +1):tid*len
           @inbounds for i in domain# tid gives each assignment for each thread
               acc += arr[i]
           end
           results[tid] = acc
       end
       sum(results)
   end
end
function threaded_sum_noninbound(arr)## for nthreads=6
   #@assert length(arr) % nthreads() == 0## should be no effect
   let results = zeros(eltype(arr), nthreads())## result reduced to nthreads-sized array
       @threads for tid in 1:nthreads() # tid := task id
           # split work
           acc = zero(eltype(arr)) # local accumulator
           len = div(length(arr), nthreads()) # len for each subjob for a thread
           domain = ((tid-1)*len +1):tid*len
           for i in domain# tid gives each assignment for each thread
               acc += arr[i]
           end
           results[tid] = acc
       end
       sum(results)
   end
end
function threaded_sum2(arr)
   #@assert length(arr) % nthreads() == 0
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
data = rand(3*2^19);
#sum([1,2,3])
#threaded_sum([1,2,3])
#threaded_sum2([1,2,3])
"""
