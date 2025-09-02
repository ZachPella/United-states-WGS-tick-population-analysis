#!/bin/bash
#SBATCH --job-name=genomicsdb_import_combined
#SBATCH --time=1-00:00:00
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=2
#SBATCH --cpus-per-task=2
#SBATCH --mem=70G # Increased memory for 193 samples vs original 61
#SBATCH --partition=batch
#SBATCH --array=0-9 # One job per scatter chunk

## Load modules and set environment
module purge
module load gatk4/4.6
export TILEDB_DISABLE_FILE_LOCKING=1

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
WORKDIR=${BASEDIR}/genotyping
REFERENCEDIR=/work/fauverlab/zachpella/practice_pop_gen/reference
REFERENCE=masked_ixodes_ref_genome.fasta
SAMPLE_LIST=${BASEDIR}/sample_list.txt
SCATTER_COUNT=10

## Get chunk info based on array task ID
CHUNK=$(printf "%04d" ${SLURM_ARRAY_TASK_ID})

## Get interval list for this chunk (use first sample as template since all should be identical)
FIRST_SAMPLE=$(sed -n "1p" ${SAMPLE_LIST})
INTERVAL_LIST_CHUNK="${WORKDIR}/scattered_intervals/${FIRST_SAMPLE}/${CHUNK}-scattered.interval_list"

## Verify interval list exists
if [ ! -f "$INTERVAL_LIST_CHUNK" ]; then
    echo "Error: Interval list not found: $INTERVAL_LIST_CHUNK"
    echo "Make sure HaplotypeCaller scatter jobs completed successfully."
    exit 1
fi

## Create job-specific directories on scratch partition
mkdir -p /scratch/$SLURM_JOBID/tmp
mkdir -p /scratch/$SLURM_JOBID/output

echo "Processing chunk ${CHUNK} using interval list: ${INTERVAL_LIST_CHUNK}"

## Build GVCF input list for this chunk across all 193 samples
GVCF_INPUT=""
GVCF_COUNT=0
MISSING_SAMPLES=""

echo "Detecting GVCF files for chunk ${CHUNK} across all samples..."

# Read through sample list and check for each sample's GVCF
while IFS= read -r SAMPLE; do
    SAMPLE_GVCF="${WORKDIR}/scattered_gvcfs/${SAMPLE}/${SAMPLE}.${CHUNK}.g.vcf"
    if [ -f "$SAMPLE_GVCF" ]; then
        GVCF_INPUT="${GVCF_INPUT} -V ${SAMPLE_GVCF}"
        ((GVCF_COUNT++))
    else
        echo "Warning: Missing GVCF for sample ${SAMPLE}, chunk ${CHUNK}: ${SAMPLE_GVCF}"
        MISSING_SAMPLES="${MISSING_SAMPLES} ${SAMPLE}"
    fi
done < "$SAMPLE_LIST"

## Validation checks
if [ -z "$GVCF_INPUT" ]; then
    echo "Error: No GVCF files found for chunk ${CHUNK}. Exiting."
    exit 1
fi

echo "Found ${GVCF_COUNT} GVCF files for chunk ${CHUNK}"
EXPECTED_SAMPLES=$(wc -l < "$SAMPLE_LIST")
if [ ${GVCF_COUNT} -ne ${EXPECTED_SAMPLES} ]; then
    echo "Warning: Expected ${EXPECTED_SAMPLES} samples but found ${GVCF_COUNT} GVCFs"
    if [ ! -z "$MISSING_SAMPLES" ]; then
        echo "Missing samples:${MISSING_SAMPLES}"
    fi
    echo "Proceeding with available samples..."
fi

## Set output paths
FINAL_GENOMICSDB_PATH="${WORKDIR}/genomicsdb_chunks/chunk_${CHUNK}"
SCRATCH_GENOMICSDB_PATH="/scratch/$SLURM_JOBID/output/genomicsdb_chunk_${CHUNK}"

## Clean up old directory if it exists
if [ -d "$FINAL_GENOMICSDB_PATH" ]; then
    echo "Removing existing GenomicsDB directory: ${FINAL_GENOMICSDB_PATH}"
    rm -rf ${FINAL_GENOMICSDB_PATH}
fi

## Create final output directory
mkdir -p "${WORKDIR}/genomicsdb_chunks"

## Run GenomicsDBImport for this chunk
echo "Running GenomicsDBImport on ${GVCF_COUNT} samples for chunk ${CHUNK}..."
echo "Memory allocation: 200G for GenomicsDB workspace"
echo "Interval list: ${INTERVAL_LIST_CHUNK}"

gatk --java-options "-Djava.io.tmpdir=/scratch/$SLURM_JOBID/tmp -Xms4G -Xmx62G -XX:ParallelGCThreads=2" \
    GenomicsDBImport \
    --genomicsdb-workspace-path ${SCRATCH_GENOMICSDB_PATH} \
    --genomicsdb-shared-posixfs-optimizations true \
    --tmp-dir /scratch/$SLURM_JOBID/tmp \
    ${GVCF_INPUT} \
    -L ${INTERVAL_LIST_CHUNK} \
    --reference ${REFERENCEDIR}/${REFERENCE}

## Check if GenomicsDBImport succeeded
if [ $? -ne 0 ]; then
    echo "Error: GenomicsDBImport failed for chunk ${CHUNK}"
    exit 1
fi

echo "✓ GenomicsDBImport completed successfully for chunk ${CHUNK}"
echo "Workspace created on scratch at: ${SCRATCH_GENOMICSDB_PATH}"

## Copy results from scratch to permanent storage
echo "Copying GenomicsDB workspace from scratch to permanent storage..."
cp -r ${SCRATCH_GENOMICSDB_PATH} ${FINAL_GENOMICSDB_PATH}

## Verify copy succeeded
if [ $? -eq 0 ] && [ -d "$FINAL_GENOMICSDB_PATH" ]; then
    echo "✓ Successfully copied GenomicsDB workspace to: ${FINAL_GENOMICSDB_PATH}"
else
    echo "Error: Failed to copy GenomicsDB workspace to permanent storage"
    exit 1
fi

## Summary
echo "=== GenomicsDB Import Summary for Chunk ${CHUNK} ==="
echo "Samples processed: ${GVCF_COUNT}"
echo "Interval list: ${INTERVAL_LIST_CHUNK}"
echo "Final workspace: ${FINAL_GENOMICSDB_PATH}"
echo "Completed at: $(date)"
printf "\n"
