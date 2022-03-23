module SlurmSubmission

struct ClusterInfo
    ntasks_per_node::Int
    mem_per_cpu::Int
    account::String
    partition::String
end

get_default_account() = read(`sacctmgr show user $USER format=DefaultAccount -nP`, String)

const SulisCluster = ClusterInfo(128, 3850, "su007-rjm", "compute")
const AvonCluster = ClusterInfo(48, 3700, "chemistryrjm", "compute")
const OracCluster = ClusterInfo(28, 4571, "chemistryrjm", "cnode")
const ArcherCluster = ClusterInfo(128, 0, "E635", "standard")

function ClusterInfo() 
    machine = read(`hostname`, String)
    if occursin("sulis", machine)
        @info "Cluster identified as Sulis"
        return SulisCluster
    elseif occursin("avon", machine)
        @info "Cluster identified as Avon"
        return AvonCluster
    elseif occursin("orac", machine)
        @info "Cluster identified as Orac"
        return OracCluster
    elseif occursin("ln", machine)
        @info "Cluster identified as Archer"
        return ArcherCluster
    else
        throw(error("Cluster not recognised."))
    end
end

struct Options
    script_name::String
    sbatch_options::Vector{String}
    julia_script::String
end

function Options(julia_script; kwargs...)
    sbatch_options = get_sbatch_options(;kwargs...)
    Options("submit.sh", sbatch_options, julia_script)
end

function get_sbatch_options(;time::String, nodes=nothing,
    partition=nothing, account=nothing, ntasks_per_node=nothing,
    total_tasks=nothing
)

    cluster = ClusterInfo()

    (partition === nothing) && (partition = cluster.partition)
    (account === nothing) && (account = cluster.account)
    (ntasks_per_node === nothing) && (ntasks_per_node = cluster.ntasks_per_node)

    if !(total_tasks === nothing)
        @info "Using `total_tasks` to determine number of nodes and tasks per node."
        nodes = (total_tasks-1) ÷ cluster.ntasks_per_node + 1
        ntasks_per_node = Int(total_tasks / nodes)
        @info "Parameters" total_tasks nodes ntasks_per_node
    elseif (nodes === nothing)
        throw(error("You must specify either `nodes` or `total_tasks`."))
    end

    options =  [
        "--time=$time"
        "--nodes=$nodes"
        "--ntasks-per-node=$ntasks_per_node"
        "--cpus-per-task=1"
        "--account=$(account)"
        "--partition=$(partition)"
    ]

    if cluster === ArcherCluster
        push!(options, "--qos=standard")
    else
        push!(options, "--mem-per-cpu=$(cluster.mem_per_cpu)")
    end

    return options
end

function write_script(options::Options, parameter_file)
    open(options.script_name, "w") do io
        println(io, "#!/bin/bash")
        for line in options.sbatch_options
            println(io, "#SBATCH $line")
        end
        println(io, "export JULIA_DEPOT_PATH=\"$(DEPOT_PATH[1])\"")
        julia_path = joinpath(Sys.BINDIR, "julia")
        println(io, join([julia_path, options.julia_script, parameter_file], " "))
    end
end

function submit_script(options::Options)
    run(`sbatch $(options.script_name)`)
    run(`rm $(options.script_name)`)
end

function submit_scripts(options, parameter_files; dry_run=false)
    @info "Submitting $(length(parameter_files)) jobs."
    for file in parameter_files
        write_script(options, file)
        dry_run ? @info("Script written but not submitted.") : submit_script(options)
    end
    @info "Success!"
end

end
