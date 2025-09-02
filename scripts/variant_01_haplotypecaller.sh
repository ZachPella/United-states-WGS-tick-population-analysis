#!/bin/bash
#SBATCH --job-name=haplotype_scatter_combined
#SBATCH --time=7-00:00:00
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err
#SBATCH --nodes=1
#SBATCH --cpus-per-task=20 # 10 chunks * 2 cpus/chunk = 20 cpus total
#SBATCH --mem=250G # 10 chunks * 28G/chunk + 40G buffer = 320G total
#SBATCH --array=1-193
#SBATCH --partition=batch

## Record relevant job info
START_DIR=$(pwd)
HOST_NAME=$(hostname)
RUN_DATE=$(date)
echo "Starting working directory: ${START_DIR}"
echo "Host name: ${HOST_NAME}"
echo "Run date: ${RUN_DATE}"
printf "\n"

## Set directories and variables
BASEDIR=/work/fauverlab/zachpella/combined_pop_gen
WORKDIR=${BASEDIR}/genotyping
REFERENCEDIR=/work/fauverlab/zachpella/practice_pop_gen/reference
REFERENCE=masked_ixodes_ref_genome.fasta
INTERVAL_LIST=${REFERENCEDIR}/${REFERENCE}.interval_list
SAMPLE_LIST=${BASEDIR}/sample_list.txt
BAMDIR1=/work/fauverlab/zachpella/scripts_ticksJune2025_10_scatter/dedup
BAMDIR2=/work/fauverlab/zachpella/scripts_ticks_and_onlineJune2025/files_not_our_ticks/dedup
SCATTER_COUNT=10
CPUS_PER_CHUNK=2
MEM_PER_CHUNK=20 # in GB

## --- Error checking and validation ---
if [ ! -f "$SAMPLE_LIST" ]; then
    echo "Error: Sample list file not found: $SAMPLE_LIST"
    exit 1
fi

TOTAL_SAMPLES=$(wc -l < "$SAMPLE_LIST")
if [ ${SLURM_ARRAY_TASK_ID} -gt ${TOTAL_SAMPLES} ]; then
    echo "Error: Array task ID ${SLURM_ARRAY_TASK_ID} exceeds number of samples (${TOTAL_SAMPLES})"
    exit 1
fi

SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$SAMPLE_LIST")
if [[ -z "$SAMPLE" ]]; then
    echo "Error: Empty sample name for array task ${SLURM_ARRAY_TASK_ID}"
    exit 1
fi

## Create sample-specific directories
mkdir -p ${WORKDIR}/scattered_intervals/${SAMPLE}
mkdir -p ${WORKDIR}/scattered_gvcfs/${SAMPLE}

## Find BAM file in either directory
if [ -f "${BAMDIR1}/${SAMPLE}.dedup.rg.sorted.bam" ]; then
    BAM_FILE="${BAMDIR1}/${SAMPLE}.dedup.rg.sorted.bam"
    echo "Found BAM in dataset 1: ${BAM_FILE}"
elif [ -f "${BAMDIR2}/${SAMPLE}.dedup.rg.sorted.bam" ]; then
    BAM_FILE="${BAMDIR2}/${SAMPLE}.dedup.rg.sorted.bam"
    echo "Found BAM in dataset 2: ${BAM_FILE}"
else
    echo "Error: Input BAM file not found for ${SAMPLE} in either directory:"
    echo "  Checked: ${BAMDIR1}/${SAMPLE}.dedup.rg.sorted.bam"
    echo "  Checked: ${BAMDIR2}/${SAMPLE}.dedup.rg.sorted.bam"
    exit 1
fi

echo "Array Task ID: ${SLURM_ARRAY_TASK_ID}"
echo "Starting Scatter-Gather HaplotypeCaller for ${SAMPLE}"
echo "Scatter count: ${SCATTER_COUNT}"
echo "Memory per chunk: ${MEM_PER_CHUNK}G"
echo "CPUs per chunk: ${CPUS_PER_CHUNK}"

## Load modules
module purge
module load gatk4/4.6

cd ${WORKDIR}

## Step 1: Split intervals
echo "Splitting intervals into ${SCATTER_COUNT} chunks..."
gatk SplitIntervals \
    -R ${REFERENCEDIR}/${REFERENCE} \
    -L ${INTERVAL_LIST} \
    --scatter-count ${SCATTER_COUNT} \
    -O scattered_intervals/${SAMPLE}/

## Step 2: Run HaplotypeCaller chunks in parallel
echo "Running ${SCATTER_COUNT} parallel HaplotypeCaller jobs with ${MEM_PER_CHUNK}G memory each..."
for i in $(seq 0 $((SCATTER_COUNT-1))); do
    CHUNK=$(printf "%04d" $i)
    SCATTERED_INTERVAL="scattered_intervals/${SAMPLE}/${CHUNK}-scattered.interval_list"
    CHUNK_GVCF="scattered_gvcfs/${SAMPLE}/${SAMPLE}.${CHUNK}.g.vcf"
    gatk --java-options "-Xmx${MEM_PER_CHUNK}G -Djava.io.tmpdir=/tmp" HaplotypeCaller \
        -R ${REFERENCEDIR}/${REFERENCE} \
        -I ${BAM_FILE} \
        -native-pair-hmm-threads ${CPUS_PER_CHUNK} \
        -L ${SCATTERED_INTERVAL} \
        -ploidy 2 \
        -O ${CHUNK_GVCF} \
        --ERC GVCF &
done

## Wait for all jobs to finish
echo "Waiting for all HaplotypeCaller jobs to complete..."
wait

## Verify all scattered GVCF files were created
echo "Verifying all scattered GVCF files were created..."
ALL_CREATED=true
for i in $(seq 0 $((SCATTER_COUNT-1))); do
    CHUNK=$(printf "%04d" $i)
    CHUNK_GVCF="scattered_gvcfs/${SAMPLE}/${SAMPLE}.${CHUNK}.g.vcf"
    if [ ! -f "${CHUNK_GVCF}" ]; then
        echo "Error: Scattered GVCF file not created: ${CHUNK_GVCF}"
        ALL_CREATED=false
    fi
done

if [ "$ALL_CREATED" = false ]; then
    echo "Error: Not all scattered GVCF files were created for ${SAMPLE}"
    exit 1
fi

echo "✓ Scatter-Gather HaplotypeCaller completed successfully for ${SAMPLE}"
echo "  Individual GVCFs are located in: scattered_gvcfs/${SAMPLE}/"
echo "  Created ${SCATTER_COUNT} scattered GVCF files:"
for i in $(seq 0 $((SCATTER_COUNT-1))); do
    CHUNK=$(printf "%04d" $i)
    echo "    scattered_gvcfs/${SAMPLE}/${SAMPLE}.${CHUNK}.g.vcf"
done
echo "Completed at: $(date)"
printf "\n"
