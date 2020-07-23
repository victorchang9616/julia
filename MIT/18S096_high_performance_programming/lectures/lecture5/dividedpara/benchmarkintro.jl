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
