module NeuronalFeatures

export findthreshold, findbursts, findmaskedthreshold

function findthreshold(V::Vector{<:Real}, Vth::Real, direction::Int = 0)
    indexes = Vector{Int64}()
    nprev = zero(Vth)
    n = zero(nprev)
    for i in 1:length(V)
        i == firstindex(V) && continue
        n = V[i]
        nprev = V[i-1]
        direction == 0 &&
        ((nprev < Vth && n ≥ Vth) || (nprev > Vth && n ≤ Vth)) &&
        push!(indexes, i)
        direction == 1 && nprev < Vth && n ≥ Vth && push!(indexes, i)
        direction == -1 && nprev > Vth && n ≤ Vth && push!(indexes, i)
    end
    return indexes
end

function findmaskedthreshold(spans, t, V, Vth, direction::Int = 0)
    s = findthreshold(V, Vth, direction)
    # reject events that happened during bursts
    for burst in spans
        s = filter(x -> !(burst[begin] ≤ t[x] ≤ burst[end]), s)
    end
    return s
end

function findbursts(s, delta)
    bs = Vector{eltype(s)}() # burst starts
    be = Vector{eltype(s)}() # burst ends
    for i in eachindex(s)
        if i !== lastindex(s) && s[i+1] - s[i] < delta && (i == 1 || s[i] - s[i-1] > delta)
            push!(bs, s[i])
        end
        if i !== firstindex(s) && (i == lastindex(s) || s[i+1] - s[i] > delta) && (s[i] - s[i-1] < delta)
            push!(be, s[i])
        end
    end
    return bs, be
end

duration(burst_start, burst_end) = burst_end - burst_start
periods(burst_durations, burst_ends) = burst_durs[1:end-1] + (burst_ends[2:end] - burst_ends[1:end-1])
frequency(burst_period) = inv(burst_period)
duty_cycle(burst_duration, burst_period) = burst_duration/burst_period

end # module NeuronalFeatures
