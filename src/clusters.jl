
struct ClusterInfo
    name::String
    options::Dict{Symbol,Any}
end

function SulisCluster()
    ClusterInfo("sulis",
        Dict{Symbol,Any}(
            :ntasks_per_node=>128,
            :mem_per_cpu=>3850,
            :account=>"su007-rjm",
            :partition=>"compute",
            :cpus_per_task=>1
        )
    )
end

function AvonCluster()
    ClusterInfo("avon",
        Dict{Symbol,Any}(
            :ntasks_per_node=>48,
            :mem_per_cpu=>3700,
            :cpus_per_task=>1
        )
    )
end

function OracCluster()
    ClusterInfo("orac",
        Dict{Symbol,Any}(
            :ntasks_per_node=>28,
            :mem_per_cpu=>4571,
            :cpus_per_task=>1
        )
    )
end

function ArcherCluster()
    ClusterInfo("archer",
        Dict{Symbol,Any}(
            :ntasks_per_node=>128,
            :account=>"e05-surfin-rjm",
            :partition=>"standard",
            :cpus_per_task=>1,
            :qos=>"standard"
        )
    )
end

function TaskFarmCluster()
    ClusterInfo("taskfarm",
        Dict{Symbol,Any}(
            :ntasks_per_node=>48,
            :mem_per_cpu=>3800,
            :cpus_per_task=>1,
            :ntasks=>48
        )
    )
end

function ClusterInfo() 
    machine = read(`hostname`, String)
    if occursin("sulis", machine)
        return SulisCluster()
    elseif occursin("avon", machine)
        return AvonCluster()
    elseif occursin("orac", machine)
        return OracCluster()
    elseif occursin("ln", machine)
        return ArcherCluster()
    elseif occursin("godzilla", machine)
        return TaskFarmCluster()
    else
        throw(error("Cluster not recognised."))
    end
end
