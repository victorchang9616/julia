using Base.Threads
using BenchmarkTools
function f_racerx()
          s = repeat(["123", "213", "231"], outer=1000)
          x = similar(s, Int)
          rx = r"1"
          @threads for i in 1:3000
              x[i] = findfirst(rx, s[i]).start
          end
          count(v -> v == 1, x)
end
function f_fix()
            s = repeat(["123", "213", "231"], outer=1000)
            x = similar(s, Int)
            rx = [Regex("1") for i in 1:nthreads()]
            @threads for i in 1:3000
                x[i] = findfirst(rx[threadid()], s[i]).start
            end
            count(v -> v == 1, x)
end

"""
a = zeros(10)
Threads.@threads for i = 1:10
           a[i] = Threads.threadid()
       end
#############################################
i = Threads.Atomic{Int}(0);

ids = zeros(6);

old_is = zeros(6);

Threads.@threads for id in 1:6
old_is[id] = Threads.atomic_add!(i, id)
ids[id] = id
end
#############################################
acc = Ref(0)

@threads for i in 1:1000
         acc[] += 1
end
###########################################
acc = Atomic{Int64}(0)


@threads for i in 1:1000
         atomic_add!(acc, 1)
end
#############################################

"""
