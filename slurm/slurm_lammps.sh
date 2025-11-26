#!/usr/bin/env bash
TASK=$1
cat >slurm_job_${TASK}.sh <<EOF
#!/usr/bin/env bash
#SBATCH --job-name=${TASK}
#SBATCH --output=slurm_output_%j.txt
#SBATCH --partition=debug
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --gres=shard:1
#SBATCH --mem=3000m
export LAMMPS_POTENTIALS=/export/lammps_jobs/potentials
nix develop git+ssh://git@github.com/TonyWu20/lammps_flake --command bash -c \\
    "mpirun --mca plm slurm \\
        -x OMPI_MCA_btl_tcp_if_include=enp6s0 \\
        -x OMPI_MCA_orte_keep_fqdn_hostnames=true \\
        -x OMP_PROC_BIND=spread \\
        -x OMP_PLACES=threads \\
       --mca pmix s1 \\
       --mca btl tcp,self \\
    lmp -sf kk -k on g 1 -pk kokkos newton on neigh half -in ${TASK}"
EOF
# sbatch slurm_job_${TASK}.sh && rm slurm_job_${TASK}.sh
