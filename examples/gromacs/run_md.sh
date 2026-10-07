#!/usr/bin/env bash
# scripts/run_md.sh: set up and run one system, one stage at a time.
# Usage: scripts/run_md.sh <prep|em|nvt|npt|md> [replica]
# Run from the project root, one stage at a time, and check each stage's output
# before the next. Needs setup/<sys>.pdb and .mdp templates in setup/mdp/
# (ions, em, nvt, npt, md) with @TEMP@ where the temperature goes.
# Explained in the BIOKT Lab Handbook, Chapter 3, §6.1.
set -euo pipefail

# ---- What this run is. Only these lines change between runs. ---------------
sys=as4             # system identifier, fixed for the whole project
ff=amber99sb-ildn   # force field, as pdb2gmx names it (an example only: not for IDPs, §3)
fftag=a99sb         # short tag for the force field in file names
wat=tip3p           # water model
temp=300            # temperature (K)
conc=0.15           # NaCl concentration (mol/L), on top of neutralising ions
stage=${1:?usage: $0 <prep|em|nvt|npt|md> [replica]}
rep=${2:-0}         # replica index, from 0
gmx=${GMX:-gmx}     # e.g. GMX=gmx_mpi where only the MPI build exists

# ---- Names, built from the choices above ----------------------------------
model=${sys}_${fftag}_${wat}    # e.g. as4_a99sb_tip3p
name=${model}_${temp}K          # e.g. as4_a99sb_tip3p_300K
top=setup/${model}.top
start=setup/${model}_start.gro  # solvated, neutralised starting structure
mkdir -p data/{prep,em,nvt,npt,md}

# grompp + mdrun for one stage: <stage> <output base name> <input .gro> [grompp options]
# The .mdp templates in setup/mdp/ contain @TEMP@ wherever the temperature goes.
run_stage() {
  local st=$1 out=$2 in=$3; shift 3
  sed "s/@TEMP@/${temp}/g" setup/mdp/${st}.mdp > ${out}.mdp
  $gmx grompp -f ${out}.mdp -c ${in} -p ${top} -po ${out}_mdout.mdp -o ${out}.tpr "$@"
  $gmx mdrun -deffnm ${out}
}

case $stage in
prep)
  # Topology. Check protonation states (§4); -his lets you choose histidines.
  (cd setup && $gmx pdb2gmx -f ${sys}.pdb -ff ${ff} -water ${wat} -ignh \
      -o ../data/prep/${model}_pdb2gmx.gro -p ${model}.top -i ${model}_posre.itp)
  # Box: 1.2 nm from solute to box edge. Not enough for an extended IDP (§4).
  $gmx editconf -f data/prep/${model}_pdb2gmx.gro -o data/prep/${model}_box.gro \
      -c -d 1.2 -bt dodecahedron
  case ${wat} in tip4p*) wbox=tip4p.gro ;; *) wbox=spc216.gro ;; esac
  $gmx solvate -cp data/prep/${model}_box.gro -cs ${wbox} -p ${top} \
      -o data/prep/${model}_solv.gro
  $gmx grompp -f setup/mdp/ions.mdp -c data/prep/${model}_solv.gro -p ${top} \
      -po data/prep/${model}_ions_mdout.mdp -o data/prep/${model}_ions.tpr
  echo SOL | $gmx genion -s data/prep/${model}_ions.tpr -p ${top} -o ${start} \
      -pname NA -nname CL -neutral -conc ${conc}
  ;;
em)
  run_stage em data/em/${model}_em ${start}
  grep -E "converged to|Potential Energy|Maximum force" data/em/${model}_em.log
  ;;
nvt)
  out=data/nvt/${name}_nvt_rep${rep}
  run_stage nvt ${out} data/em/${model}_em.gro -r data/em/${model}_em.gro
  echo Temperature | $gmx energy -f ${out}.edr -o ${out}_temperature.xvg
  ;;
npt)
  in=data/nvt/${name}_nvt_rep${rep}
  out=data/npt/${name}_npt_rep${rep}
  run_stage npt ${out} ${in}.gro -r ${in}.gro -t ${in}.cpt
  printf "Pressure\nDensity\n" | $gmx energy -f ${out}.edr -o ${out}_pressure_density.xvg
  ;;
md)
  in=data/npt/${name}_npt_rep${rep}
  run_stage md data/md/${name}_md_rep${rep} ${in}.gro -t ${in}.cpt
  ;;
*)
  echo "unknown stage: ${stage}" >&2; exit 1 ;;
esac
