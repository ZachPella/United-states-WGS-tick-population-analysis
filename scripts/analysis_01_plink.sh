#!/bin/bash
#SBATCH --job-name=pop_structure
#SBATCH --time=12:00:00
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err
#SBATCH --nodes=1
#SBATCH --cpus-per-task=12
#SBATCH --mem=90G
#SBATCH --partition=batch

## Record relevant job info
START_DIR=$(pwd)
HOST_NAME=$(hostname)
RUN_DATE=$(date)
echo "Starting working directory: ${START_DIR}"
echo "Host name: ${HOST_NAME}"
echo "Run date: ${RUN_DATE}"
printf "\n"

## Set working directory and variables
BASEDIR=/work/fauverlab/zachpella/combined_pop_gen
WORKDIR=${BASEDIR}
INPUT_VCF=${BASEDIR}/genotyping/cohort_combined_193samples_snps_only_variant_filtered_passed_column_only_maf_and_missingness_final.vcf.gz

cd ${WORKDIR}

## Create output directory
mkdir -p population_structure

## Check if input VCF exists
if [ ! -f "${INPUT_VCF}" ]; then
    echo "Error: Input VCF file not found: ${INPUT_VCF}"
    exit 1
fi

echo "Using input VCF: ${INPUT_VCF}"
echo "Output directory: ${WORKDIR}/population_structure"

## Load modules
module purge
module load plink2 # Only plink2 is needed

## Step 1: Perform LD pruning and create a list of variants to keep
echo "Performing linkage disequilibrium pruning..."
plink2 \
    --vcf ${INPUT_VCF} \
    --double-id \
    --allow-extra-chr \
    --set-missing-var-ids @:# \
    --indep-pairwise 50 10 0.1 \
    --out population_structure/tick_population_ld

## Verify LD pruning output was created
if [ ! -f "population_structure/tick_population_ld.prune.in" ]; then
    echo "Error: LD pruning output files not created"
    exit 1
fi

## Step 2: Extract LD-pruned variants, make a bed file, and perform PCA in a single command
echo "Extracting LD-pruned variants and performing PCA analysis..."
plink2 \
    --vcf ${INPUT_VCF} \
    --double-id \
    --allow-extra-chr \
    --set-missing-var-ids @:# \
    --extract population_structure/tick_population_ld.prune.in \
    --make-bed \
    --pca 20 \
    --out population_structure/tick_pca_pruned

## Verify PCA output was created
if [ ! -f "population_structure/tick_pca_pruned.eigenvec" ]; then
    echo "Error: PCA output files not created"
    exit 1
fi

echo "✓ Population structure analysis with LD pruning completed successfully"
echo "  LD pruning results: population_structure/tick_population_ld.*"
echo "  PCA results: population_structure/tick_pca_pruned.*"
echo "Completed at: $(date)"
printf "\n"
