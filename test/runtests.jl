
using Test, NeuroFeatures, Serialization, Plots

@testset "Neuron Features" begin
    
    Vth = 1
    series = zeros(Int64, 10)

    series[2] = 1
    series[4] = -1
    series[8] = 5
    series[9] = 5
    s = findthreshold(series, Vth, 1)
    @test s == [2,8]

    s = findthreshold(series, -Vth, -1)
    @test s == [4]

    s = findthreshold(series, Vth, 0)
    @test s == [2,8,10]

    data = deserialize(joinpath(@__DIR__, "../assets/stg_example.data"))
    data_t = data[:,1]
    data_Vm = data[:,2]
    ap_idxs = findthreshold(data_Vm, 10.0, 1)
    ap_times = data_t[ap_idxs]
    
    @test length(ap_idxs) == 64
    @test ap_times ≈ deserialize(joinpath(@__DIR__, "../assets/stg_aptimes.data"))

    # To check visually:

    # markers = fill(10.0, size(ap_idxs))
    # plot(data_t, data_Vm)
    # scatter!(ap_times, markers)
    
    δ = 100.0 # interspike interval for bursts
    bs, be = findbursts(ap_times, δ) # returns timestamps of burst begin and burst ending
    # vline!(x) for bs and be OR vspan!(x) where spans are drawn between each consecutive pair
    @test length(bs) == 6 && length(be) == 6
    
    #bursts = zeros(length(bs) + length(be))
    #bursts[1:2:end] = bs
    #bursts[2:2:end] = be
    #vspan(bursts)
    #plot!(data_t, data_Vm)
    #scatter!(ap_times, markers)
    
    ltholds = [-45.0,-50.0,-55.0]

    spans = zip(bs, be)
    l1 = findmaskedthreshold(spans, data_t, data_Vm, ltholds[1], -1)
    #l2 = findmaskedthreshold(spans, data_t, data_Vm, ltholds[2], -1)
    #l3 = findmaskedthreshold(spans, data_t, data_Vm, ltholds[3], -1)
    
    l1_markers = fill(ltholds[1], size(l1))
    #l2_markers = fill(ltholds[2], size(l2))
    #l3_markers = fill(ltholds[3], size(l3))

    l1_times = data_t[l1]
    #l2_times = data_t[l2]
    #l3_times = data_t[l3]

    scatter!(l1_times, l1_markers)
    #scatter!(l2_times, l2_markers)
    #scatter!(l3_times, l3_markers)
   
end
