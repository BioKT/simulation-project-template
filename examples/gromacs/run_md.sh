#!/usr/bin/env bash
# scripts/run_md.sh: from a PDB file to production, one step after another.
# Run from the project root. Needs setup/<sys>.pdb and .mdp templates in
# setup/mdp/ (ions, em, nvt, npt, md) with @TEMP@ where the temperature goes.
# Explained in the BIOKT Lab Handbook, Chapter 3, §6.1.
set -euo pipefail

# ---- What this run is. Only these lines change between runs. ---------------
sys=as4             # system identifier, fixed for the whole project
ff=amber99sb-ildn   # force field, as pdb2gmx names it (an example only: not for IDPs, §3)
fftag=a99sb         # short tag for the force field in file names
wat=tip3p           # water model
temp=300            # temperature (K)
conc=0.15           # NaCl concentration (mol/L), on top of neutralising ions
gmx=${GMX:-gmx}     # e.g. GMX=gmx_mpi where only the MPI build exists

# ---- Names, built from the choices above ----------------------------------
model=${sys}_${fftag}_${wat}    # e.g. as4_a99sb_tip3p
name=${model}_${temp}K          # e.g. as4_a99sb_tip3p_300K
top=setup/${model}.top
start=setup/${model}_start.gro  # solvated, neutralised starting structure
prep=data/prep/${model}
em=data/em/${model}_em
mkdir -p data/{prep,em,nvt,npt,md}

# ---- 1. Topology ----------------------------------------------------------
# Check protonation states (§4); -his lets you choose histidines.
# Run inside setup/ so that the topology includes its .itp files by name.
cd setup
$gmx pdb2gmx -f ${sys}.pdb -ff ${ff} -water ${wat} -ignh \
    -o ../${prep}_pdb2gmx.gro -p ${model}.top -i ${model}_posre.itp
cd ..

# ---- 2. Box ---------------------------------------------------------------
# 1.2 nm from solute to box edge. Not enough for an extended IDP (§4).
$gmx editconf -f ${prep}_pdb2gmx.gro -o ${prep}_box.gro -c -d 1.2 -bt dodecahedron

# ---- 3. Solvent -----------------------------------------------------------
# spc216.gro is the solvent box for 3-site water; use tip4p.gro for 4-site.
$gmx solvate -cp ${prep}_box.gro -cs spc216.gro -p ${top} -o ${prep}_solv.gro

# ---- 4. Ions --------------------------------------------------------------
$gmx grompp -f setup/mdp/ions.mdp -c ${prep}_solv.gro -p ${top} \
    -po ${prep}_ions_mdout.mdp -o ${prep}_ions.tpr
echo SOL | $gmx genion -s ${prep}_ions.tpr -p ${top} -o ${start} \
    -pname NA -nname CL -neutral -conc ${conc}

# ---- 5. Energy minimisation -----------------------------------------------
$gmx grompp -f setup/mdp/em.mdp -c ${start} -p ${top} -po ${em}_mdout.mdp -o ${em}.tpr
$gmx mdrun -deffnm ${em}
grep -E "converged to|Potential Energy|Maximum force" ${em}.log
grep -q "converged to Fmax" ${em}.log || { echo "EM did not converge" >&2; exit 1; }

# ---- 6-8. Equilibration and production, for each replica -------------------
# Replicas here differ only in their initial velocities (gen_seed = -1).
for rep in 0 1 2; do
  nvt=data/nvt/${name}_nvt_rep${rep}
  npt=data/npt/${name}_npt_rep${rep}
  md=data/md/${name}_md_rep${rep}

  # 6. NVT: bring the system to temperature, solute restrained
  sed "s/@TEMP@/${temp}/g" setup/mdp/nvt.mdp > ${nvt}.mdp
  $gmx grompp -f ${nvt}.mdp -c ${em}.gro -r ${em}.gro -p ${top} -po ${nvt}_mdout.mdp -o ${nvt}.tpr
  $gmx mdrun -deffnm ${nvt}
  echo Temperature | $gmx energy -f ${nvt}.edr -o ${nvt}_temperature.xvg

  # 7. NPT: bring the system to density, solute restrained
  sed "s/@TEMP@/${temp}/g" setup/mdp/npt.mdp > ${npt}.mdp
  $gmx grompp -f ${npt}.mdp -c ${nvt}.gro -r ${nvt}.gro -t ${nvt}.cpt -p ${top} \
      -po ${npt}_mdout.mdp -o ${npt}.tpr
  $gmx mdrun -deffnm ${npt}
  printf "Pressure\nDensity\n" | $gmx energy -f ${npt}.edr -o ${npt}_pressure_density.xvg

  # 8. Production
  sed "s/@TEMP@/${temp}/g" setup/mdp/md.mdp > ${md}.mdp
  $gmx grompp -f ${md}.mdp -c ${npt}.gro -t ${npt}.cpt -p ${top} -po ${md}_mdout.mdp -o ${md}.tpr
  $gmx mdrun -deffnm ${md}
done
