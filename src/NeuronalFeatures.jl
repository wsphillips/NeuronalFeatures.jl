module NeuronalFeatures

export findthreshold, findbursts, findmaskedthreshold, findlags
export duration, periods, duty_cycle, frequency
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

function findlags(s, V, t, lthold)
    lag_indexes = findthreshold(V, lthold, -1)
    start_off = first(s) > first(lag_indexes)
    end_off = last(s) > last(lag_indexes)
    if length(lag_indexes) == length(s) && !(start_off || end_off)
        return t[lag_indexes] - t[s]
    else
        s_adj = s[begin:end-end_off] 
        l_adj = lag_indexes[begin+start_off:end]
        if length(l_adj) == length(s_adj)
            return t[l_adj] - t[s_adj]
        else
            return 1e6
        end
    end
end

duration(burst_start, burst_end) = burst_end - burst_start
periods(burst_durs, burst_ends) = burst_durs[1:end-1] + (burst_ends[2:end] - burst_ends[1:end-1])
duty_cycle(burst_duration, burst_period) = burst_duration/burst_period

function burst_frequency(t, V)
    s = findthreshold(V, -20.0, 1)
    spike_times = t[s]
    bs, be = findbursts(spike_times, 100.0)
    mean_period = mean(bs[2:end] - bs[1:end-1])
    return inv(mean_period)
end

function duty_cycle(t, V)
    s = findthreshold(V, -20.0, 1)
    spike_times = t[s]
    bs, be = findbursts(spike_times, 100.0)
    return mean(be - be)
end

end # module NeuronalFeatures
