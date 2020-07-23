using Base.Threads
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
