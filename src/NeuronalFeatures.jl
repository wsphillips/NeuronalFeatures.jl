module NeuronalFeatures

using Statistics

export findthreshold, findbursts, findmaskedthreshold, findlags, spiketimes
export burst_duration, burst_period, duty_cycle, burst_frequency

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

# Maybe better if we discard unmatched burst start/ends instead of using boundary fallback?
function findbursts(s, delta = 100.0)
    isempty(s) && return []
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
    return collect(zip(bs, be))
end

function findlags(t, V, st, lthold = -35.0)
    lag_times = t[findthreshold(V, lthold, -1)]
    start_off = first(st) > first(lag_times)
    end_off = last(st) > last(lag_times)
    if length(lag_times) == length(st) && !(start_off || end_off)
        return lag_times - st
    else
        s_adj = st[begin:end-end_off] 
        l_adj = lag_times[begin+start_off:end]
        if length(l_adj) == length(s_adj)
            return t[l_adj] - t[s_adj]
        else
            return 1e6 # FIXME: this is a hack/placeholder, we need something else here
        end
    end
end

#function findlags(t, V, lthold = -35.0)
#    st = spiketimes(t, V)
#    return findlags(t, V, st, lthold)
#end

function spiketimes(t, V, thold = -20.0)
    s = findthreshold(V, thold, 1)
    return t[s]
end

function burst_duration(bursts)
    isempty(bursts) && return 0.0
    mean(burst[end] - burst[begin] for burst in bursts)
end

function burst_duration(t, V) 
    st = spiketimes(t, V)
    bursts = findbursts(spike_times, 100.0)
    return burst_duration(bursts)
end

function burst_period(bursts)
    length(bursts) < 2 && return Inf
    mean(bursts[i+1][begin] - bursts[i][begin] for i in 1:length(bursts)-1)
end

function burst_period(t, V)
    st = spiketimes(t, V)
    bursts = findbursts(spike_times, 100.0)
    return burst_period(bursts)
end

function burst_frequency(t, V)
    p = burst_period(t,V)
    p == Inf && return 0.0
    return inv(p)
end

function burst_frequency(bursts)
    p = burst_period(bursts)
    p == Inf && return 0.0
    return inv(p)
end

duty_cycle(t, V) = burst_duration(t, V)/burst_period(t, V)
duty_cycle(bursts) = burst_duration(bursts)/burst_period(bursts)

end # module NeuronalFeatures
