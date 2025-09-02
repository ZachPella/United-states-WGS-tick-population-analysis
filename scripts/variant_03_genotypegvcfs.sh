#!/bin/bash
#SBATCH --job-name=genotype_gvcfs_combined
#SBATCH --time=7-00:00:00
#SBATCH --output=%x_%A_%a.out
#SBATCH --error=%x_%A_%a.err
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=2
#SBATCH --mem=500G # Increased memory for 193 samples
#SBATCH --partition=batch
#SBATCH --array=0-9 # One job per scatter chunk

## Load modules
module purge
module load gatk4/4.6

## Record relevant job info
START_DIR=$(pwd)
HOST_NAME=$(hostname)
RUN_DATE=$(date)
echo "Starting working directory: ${START_DIR}"
echo "Host name: ${HOST_NAME}"
echo "Run date: ${RUN_DATE}"
printf "\n"

## Set up working directories and variables
BASEDIR=/work/fauverlab/zachpella/combined_pop_gen
WORKDIR=${BASEDIR}/genotyping
REFERENCEDIR=/work/fauverlab/zachpella/practice_pop_gen/reference
REFERENCE=masked_ixodes_ref_genome.fasta
SAMPLE_LIST=${BASEDIR}/sample_list.txt
GENOMICSDB_DIR=${WORKDIR}/genomicsdb_chunks

## Get chunk info based on array task ID
CHUNK=$(printf "%04d" ${SLURM_ARRAY_TASK_ID})

## Set paths for this chunk
FIRST_SAMPLE=$(sed -n "1p" ${SAMPLE_LIST})
INTERVAL_LIST_CHUNK="${WORKDIR}/scattered_intervals/${FIRST_SAMPLE}/${CHUNK}-scattered.interval_list"
GENOMICSDB_CHUNK_PATH="${GENOMICSDB_DIR}/chunk_${CHUNK}"

## Set output paths
FINAL_OUTPUT_DIR=${WORKDIR}/genotyped_vcfs
OUTPUT_VCF_NAME="chunk_${CHUNK}_genotyped.vcf.gz"
FINAL_VCF_PATH="${FINAL_OUTPUT_DIR}/${OUTPUT_VCF_NAME}"

echo "Processing chunk ${CHUNK}"
echo "GenomicsDB workspace: ${GENOMICSDB_CHUNK_PATH}"
echo "Interval list: ${INTERVAL_LIST_CHUNK}"
echo "Output VCF: ${FINAL_VCF_PATH}"

## Validation checks
if [ ! -d "$GENOMICSDB_CHUNK_PATH" ]; then
    echo "Error: GenomicsDB workspace not found: ${GENOMICSDB_CHUNK_PATH}"
    echo "Make sure GenomicsDBImport completed successfully for chunk ${CHUNK}"
    exit 1
fi

if [ ! -f "$INTERVAL_LIST_CHUNK" ]; then
    echo "Error: Interval list not found: ${INTERVAL_LIST_CHUNK}"
    exit 1
fi

## Create job-specific directories on scratch
mkdir -p /scratch/$SLURM_JOBID/tmp
mkdir -p /scratch/$SLURM_JOBID/output

## Copy required files to scratch for performance
echo "Copying reference files and GenomicsDB to scratch..."
cp "${REFERENCEDIR}/${REFERENCE}" /scratch/$SLURM_JOBID/
cp "${REFERENCEDIR}/${REFERENCE}.fai" /scratch/$SLURM_JOBID/
cp "${REFERENCEDIR}/${REFERENCE%.*}.dict" /scratch/$SLURM_JOBID/
cp "${INTERVAL_LIST_CHUNK}" /scratch/$SLURM_JOBID/

echo "Copying GenomicsDB workspace to scratch (this may take a few minutes)..."
cp -r "${GENOMICSDB_CHUNK_PATH}" /scratch/$SLURM_JOBID/

## Verify copy succeeded
if [ ! -d "/scratch/$SLURM_JOBID/chunk_${CHUNK}" ]; then
    echo "Error: Failed to copy GenomicsDB workspace to scratch"
    exit 1
fi

## Run GenotypeGVCFs for the current chunk
echo "Starting GenotypeGVCFs for chunk ${CHUNK} with 193 samples..."
echo "Java memory allocation: 200G"
echo "Processing genomic interval: $(basename "${INTERVAL_LIST_CHUNK}")"

gatk --java-options "-Djava.io.tmpdir=/scratch/$SLURM_JOBID -Xms4G -Xmx400G -XX:ParallelGCThreads=2" \
    GenotypeGVCFs \
    -R /scratch/$SLURM_JOBID/${REFERENCE} \
    -V "gendb:///scratch/$SLURM_JOBID/chunk_${CHUNK}" \
    -O /scratch/$SLURM_JOBID/output/"${OUTPUT_VCF_NAME}" \
    -L /scratch/$SLURM_JOBID/$(basename "${INTERVAL_LIST_CHUNK}")

## Copy final VCF and index back to permanent storage
echo "Copying final VCF and index to permanent storage..."
mkdir -p "${FINAL_OUTPUT_DIR}"
cp /scratch/$SLURM_JOBID/output/"${OUTPUT_VCF_NAME}" "${FINAL_OUTPUT_DIR}/"


## Summary
echo "=== GenotypeGVCFs Summary for Chunk ${CHUNK} ==="
echo "Samples processed: 193"
echo "Genomic interval: $(basename "${INTERVAL_LIST_CHUNK}")"
echo "Output VCF: ${FINAL_VCF_PATH}"
echo "Completed at: $(date)"
printf "\n"
