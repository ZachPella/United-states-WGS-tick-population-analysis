#!/bin/bash
#SBATCH --job-name=gather_vcfs_combined
#SBATCH --time=1-00:00:00
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=80G # Increased memory for 193 samples
#SBATCH --partition=batch

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

## Set up directories
BASEDIR=/work/fauverlab/zachpella/combined_pop_gen
INPUT_DIR=${BASEDIR}/genotyping/genotyped_vcfs
FINAL_OUTPUT_DIR=${BASEDIR}/genotyping
FINAL_VCF="cohort_combined_193samples_final.vcf.gz"
FINAL_VCF_PATH="${FINAL_OUTPUT_DIR}/${FINAL_VCF}"

echo "Input directory: ${INPUT_DIR}"
echo "Output directory: ${FINAL_OUTPUT_DIR}"
echo "Final VCF name: ${FINAL_VCF}"

## Validation - check input directory exists
if [ ! -d "$INPUT_DIR" ]; then
    echo "Error: Input directory not found: ${INPUT_DIR}"
    echo "Make sure GenotypeGVCFs completed successfully for all chunks"
    exit 1
fi

## Create a sorted list of input VCFs to ensure proper order
echo "Detecting chunk VCF files..."
INPUT_VCFS=()
CHUNK_COUNT=0

for i in $(seq 0 9); do
    CHUNK=$(printf "%04d" $i)
    VCF_FILE="${INPUT_DIR}/chunk_${CHUNK}_genotyped.vcf.gz"

    if [ -f "$VCF_FILE" ]; then
        INPUT_VCFS+=("-I" "${VCF_FILE}")
        ((CHUNK_COUNT++))
        echo "  Found chunk ${CHUNK}: ${VCF_FILE}"

        # Check file size
        VCF_SIZE=$(du -sh "$VCF_FILE" | cut -f1)
        echo "    Size: ${VCF_SIZE}"
    else
        echo "  Missing chunk ${CHUNK}: ${VCF_FILE}"
    fi
done

## Validation - check we have all expected chunks
if [ ${CHUNK_COUNT} -ne 10 ]; then
    echo "Error: Expected 10 chunk VCFs but found ${CHUNK_COUNT}"
    echo "Missing chunks will cause gaps in the final VCF"
    exit 1
fi

echo "✓ Found all ${CHUNK_COUNT} chunk VCFs"

## Check if final VCF already exists and handle accordingly
if [ -f "$FINAL_VCF_PATH" ]; then
    echo "Warning: Final VCF already exists: ${FINAL_VCF_PATH}"
    echo "Creating backup..."
    mv "${FINAL_VCF_PATH}" "${FINAL_VCF_PATH}.backup.$(date +%Y%m%d_%H%M%S)"
fi

## Create scratch directory for temporary operations
mkdir -p /scratch/$SLURM_JOBID

## Run GatherVcfs
echo "=== Starting GatherVcfs to combine all genotyped VCFs ==="
echo "Combining ${CHUNK_COUNT} chunks from 193 samples"
echo "Memory allocation: 60G Java heap"
echo "Temporary directory: /scratch/$SLURM_JOBID"

gatk --java-options "-Xms10G -Xmx60G -Djava.io.tmpdir=/scratch/$SLURM_JOBID" GatherVcfs \
    "${INPUT_VCFS[@]}" \
    -O "${FINAL_VCF_PATH}"

## Check if GatherVcfs succeeded
if [ $? -ne 0 ]; then
    echo "Error: GatherVcfs failed"
    exit 1
fi

## Verify final VCF was created
if [ ! -f "$FINAL_VCF_PATH" ]; then
    echo "Error: Final VCF was not created: ${FINAL_VCF_PATH}"
    exit 1
fi

echo "✓ GatherVcfs completed successfully"

## Generate summary statistics
FINAL_VCF_SIZE=$(du -sh "$FINAL_VCF_PATH" | cut -f1)
echo "Final VCF size: ${FINAL_VCF_SIZE}"

## Check if index was created
if [ -f "${FINAL_VCF_PATH}.tbi" ]; then
    INDEX_SIZE=$(du -sh "${FINAL_VCF_PATH}.tbi" | cut -f1)
    echo "Index file size: ${INDEX_SIZE}"
else
    echo "Note: No index file was created (this is normal for GatherVcfs)"
fi

## Optional: Create index if needed (uncomment if you want automatic indexing)
# echo "Creating index for final VCF..."
# gatk --java-options "-Xms4G -Xmx20G" IndexFeatureFile -I "${FINAL_VCF_PATH}"

## Clean up scratch
rm -rf /scratch/$SLURM_JOBID

## Summary
echo "=== Final VCF Assembly Complete ==="
echo "Input chunks processed: ${CHUNK_COUNT}"
echo "Total samples: 193"
echo "Final VCF location: ${FINAL_VCF_PATH}"
echo "Final VCF size: ${FINAL_VCF_SIZE}"
echo "Completed at: $(date)"
printf "\n"

echo "Next steps:"
echo "1. Validate VCF with: gatk ValidateVariants -V ${FINAL_VCF_PATH} -R <reference>"
echo "2. Generate summary stats with: bcftools stats ${FINAL_VCF_PATH}"
echo "3. Create index if needed: gatk IndexFeatureFile -I ${FINAL_VCF_PATH}"
