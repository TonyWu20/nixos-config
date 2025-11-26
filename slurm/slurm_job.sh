#!/usr/bin/env bash
TASK=$1
CORES=${2:-44}
cat >slurm_job_${TASK}.sh <<EOF
#!/usr/bin/env bash
#SBATCH --job-name=${TASK}
#SBATCH --output=slurm_output_%j.txt
#SBATCH --partition=debug
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=${CORES}
#SBATCH --cpus-per-task=1
#SBATCH --mem=30000m
nix develop git+ssh://git@github.com/TonyWu20/CASTEP-25.12-nixos#castep_25_mkl --command bash -c \\
    "mpirun --mca plm slurm \\
        -x OMPI_MCA_btl_tcp_if_include=enp6s0 \\
        -x OMPI_MCA_orte_keep_fqdn_hostnames=true \\
       --mca pmix s1 \\
       --mca btl tcp,self \\
       --use-hwthread-cpus \\
	--map-by numa --bind-to numa \\
    castep.mpi ${TASK}"
EOF
# sbatch slurm_job_${TASK}.sh && rm slurm_job_${TASK}.sh
