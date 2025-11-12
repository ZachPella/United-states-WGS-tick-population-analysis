#!/bin/bash
#SBATCH --job-name=select_passing_only
#SBATCH --partition=batch
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=20G
#SBATCH --time=0-2:00:00
#SBATCH --error=%x_%j.err
#SBATCH --output=%x_%j.out

# Purge any existing modules and load the required GATK version
module purge
module load gatk4/4.6

# Define your input and output paths
# INPUT_FILTERED_VCF: This is the VCF from your VariantFiltration step (script 02)
# OUTPUT_PASSING_ONLY_VCF: This will be the new VCF containing only the PASSING variants
BASEDIR=/work/fauverlab/zachpella/combined_pop_gen
INPUT_FILTERED_VCF="${BASEDIR}/genotyping/cohort_combined_193samples_snps_only_variant_filtered_final.vcf.gz"
OUTPUT_PASSING_ONLY_VCF="${BASEDIR}/genotyping/cohort_combined_193samples_snps_only_variant_filtered_passed_column_only_final.vcf.gz"

echo "Creating a VCF with only the variants that passed the filters..."

# Use GATK's SelectVariants tool to select only the variants with the "PASS" flag.
# The '--select' argument with the JEXL expression 'vc.isNotFiltered()'
# will select only the variants where the FILTER field is not empty (i.e., "PASS").
# The VCF index (.tbi file) for the input VCF must exist for this to work correctly.
# If it doesn't, you can run 'gatk IndexFeatureFile --input ${INPUT_FILTERED_VCF}' first.
gatk --java-options "-Xms2G -Xmx15G" SelectVariants \
    --variant "${INPUT_FILTERED_VCF}" \
    --output "${OUTPUT_PASSING_ONLY_VCF}" \
    --exclude-filtered

echo "SelectVariants completed."
echo "VCF with passing-only variants created: ${OUTPUT_PASSING_ONLY_VCF}"
echo "Script finished successfully."
