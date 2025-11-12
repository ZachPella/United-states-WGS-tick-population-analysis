# U.S. Tick Population Genomics Pipeline

**Comprehensive population genomics analysis of *Ixodes scapularis* across the United States**

## Overview

This repository contains a comprehensive 17-step bioinformatics pipeline for analyzing population structure and genetic diversity in blacklegged ticks (*Ixodes scapularis*) using whole-genome sequencing data across the United States. The pipeline processes tick samples from multiple states through quality control, variant calling, filtering, and population genetic analysis to reveal continental-scale population structure and evolutionary patterns.
<img width="1382" height="989" alt="tick_pca_colored_by_NE_county" src="https://github.com/user-attachments/assets/a7f618e0-ae9a-4497-af83-90e5a31ac07f" />
<img width="1377" height="989" alt="tick_pca_all_samples_NE_north_and_south_all_else_black_or_white" src="https://github.com/user-attachments/assets/25273d05-fe59-42de-bbf9-4d78ef688af8" />
<img width="2701" height="1990" alt="image0" src="https://github.com/user-attachments/assets/06612793-9f3e-4c73-b0ad-b011b7c5407e" />
![unnamed](https://github.com/user-attachments/assets/3dc991d1-07ef-475a-b53e-bcc359ec4930)
![unnamed](https://github.com/user-attachments/assets/cfea9503-542a-49a6-8d97-acc67dfe2eb3)



## Pipeline Workflow

### 🔵 Preprocessing (Steps 1-8)
1. **Concatenate Reads** - Combine multi-lane sequencing files
2. **Fastp QC** - Quality control and adapter trimming  
3. **FastQC** - Post-cleaning quality assessment
4. **BWA Alignment** - Map reads to *I. scapularis* reference genome
5. **SAM to BAM** - Convert and coordinate-sort alignments
6. **Add Read Groups** - GATK metadata preparation for multi-sample analysis
7. **Remove Duplicates** - PCR artifact removal and library complexity assessment
8. **Summary Statistics** - Comprehensive quality control reporting

### 🟢 Variant Calling (Steps 9-11)
9. **HaplotypeCaller** - Individual sample variant discovery with scatter-gather optimization
10. **GenomicsDB** - Consolidate variant data for scalable joint calling
11. **Joint Genotyping** - Population-scale variant calling across all US samples

### 🟠 Filtering (Steps 12-15)
12. **Select SNPs** - Extract SNPs for population genetic analysis
13. **Hard Filtering** - Apply GATK best practices quality filters
14. **Select PASS** - Retain only high-confidence variants
15. **Population Filters** - MAF ≥5% and missingness ≤30% optimization

### 🟣 Analysis (Steps 16-17)
16. **PLINK + PCA** - Population structure and genetic diversity analysis
17. **Visualization** - Publication-quality plots and geographic interpretation

## Key Features

- **Continental Scale**: Designed for large-scale analysis across the entire US range of *I. scapularis*
- **GATK Best Practices**: Rigorous variant calling following current genomics standards
- **Scalable Architecture**: Optimized scatter-gather processing for hundreds of samples
- **Geographic Integration**: Population structure analysis with spatial context
- **Publication Ready**: High-quality visualizations and comprehensive documentation
- **Reproducible Methodology**: Detailed step-by-step documentation for transparency

## Dataset Scope

- **Geographic Coverage**: Multi-state sampling across the *I. scapularis* range
- **Sample Scale**: Designed for 200+ tick samples (expandable architecture)
- **Sequencing Platform**: NovaSeq whole-genome sequencing
- **Data Volume**: Multi-TB genomic dataset processing capability
- **Population Focus**: Continental population structure and phylogeography

## Scientific Applications

This pipeline enables investigation of:
- **Population Structure**: Geographic patterns of genetic differentiation
- **Gene Flow**: Migration and connectivity across the US range
- **Demographic History**: Population expansion, bottlenecks, and founder effects
- **Local Adaptation**: Genetic signatures of adaptation to regional environments
- **Disease Ecology**: Population genetic context for pathogen transmission
- **Conservation Genetics**: Genetic diversity assessment for species management

## Technical Specifications

- **Platform**: SLURM-based HPC cluster environments
- **Core Tools**: GATK4, BWA-MEM, PLINK2, VCFtools, samtools
- **Languages**: Bash scripting, Python visualization, R statistical analysis
- **Memory Optimization**: Scalable memory allocation based on sample size
- **Processing Strategy**: Scatter-gather parallelization for computational efficiency

## Repository Structure

```
├── scripts/                    # Complete 17-step pipeline scripts
│   ├── preprocess_*.sh        # Steps 1-8: Data preparation and QC
│   ├── variant_*.sh           # Steps 9-11: GATK variant calling
│   ├── filter_*.sh            # Steps 12-15: Quality filtering
│   └── analysis_*.sh          # Steps 16-17: Population analysis
├── docs/
│   ├── pipeline-documentation.md  # Comprehensive methodology guide
│   ├── parameter-optimization.md  # Sample size scaling guidelines
│   └── troubleshooting.md         # Common issues and solutions
├── visualization/
│   ├── pca_generation.py          # Advanced PCA plotting
│   ├── geographic_analysis.R      # Spatial population genetics
│   └── diversity_metrics.py       # Population genetic statistics
├── config/
│   ├── sample_template.txt        # Sample list format
│   └── cluster_configs/           # HPC-specific configurations
└── README.md                      # This overview
```

## Quick Start Guide

### Prerequisites
- SLURM-based HPC cluster access
- Required software modules: GATK4, BWA, PLINK2, VCFtools, samtools, fastp, FastQC
- Reference genome: *I. scapularis* masked reference assembly

### Basic Usage
1. **Prepare sample list**: Create `sample_list.txt` with one sample name per line
2. **Configure paths**: Update base directory paths in all scripts for your environment  
3. **Run preprocessing**: Execute steps 1-8 sequentially
4. **Variant calling**: Run steps 9-11 for population variant discovery
5. **Filter and analyze**: Complete steps 12-17 for population structure analysis
6. **Visualize results**: Generate publication-quality figures with provided scripts

### Scaling for Large Datasets
The pipeline automatically scales resource allocation based on sample size:
- **Memory**: Increases proportionally with sample count
- **Processing time**: Array job optimization for sample-parallel steps
- **Storage**: Compressed intermediate files and organized directory structure
- **Quality control**: Sample size-aware statistical thresholds

## Key Methodological Advances

### Computational Optimization
- **Scatter-gather processing**: Parallel variant calling across genomic intervals
- **Memory-efficient joint calling**: GenomicsDB-based population analysis
- **Resource scaling**: Dynamic allocation based on dataset size
- **I/O optimization**: Scratch space utilization for intensive operations

### Quality Control Rigor
- **Multi-stage filtering**: Technical and population-level quality assessment
- **Comprehensive statistics**: Detailed metrics at every pipeline stage
- **Comparative analysis**: Before/after filtering assessment for parameter optimization
- **Sample-level QC**: Individual sample quality evaluation and outlier detection

### Population Genetic Focus
- **Geographic integration**: Spatial context for population structure analysis
- **Evolutionary interpretation**: Population genetic statistics with biological meaning
- **Visualization excellence**: Publication-ready figures with statistical annotations
- **Scalable analysis**: Methods that work from regional to continental scales

## Expected Outputs

### Data Products
- **High-quality variant dataset**: Population-filtered SNPs suitable for genetic analysis
- **Population structure results**: PCA analysis revealing geographic genetic patterns
- **Quality control reports**: Comprehensive metrics documenting pipeline performance
- **Visualization suite**: Publication-ready figures and interactive plots

### Biological Insights
- **Continental population structure**: Major genetic divisions across the US range
- **Regional differentiation**: Fine-scale population genetic patterns
- **Migration patterns**: Gene flow and connectivity between populations
- **Demographic history**: Population expansion and colonization patterns
- **Adaptive potential**: Genetic diversity distribution across populations

## Citation and Usage

If you use this pipeline in your research, please cite:
- **Pipeline methodology**: [Repository DOI]
- **Key software**: GATK, BWA-MEM, PLINK2 citations
- **Reference genome**: *I. scapularis* genome assembly citation

## Support and Contributing

- **Issues**: Report bugs or request features via GitHub Issues
- **Documentation**: Comprehensive guides in `/docs` directory  
- **Community**: Contributions welcome via pull requests


**Input:** Multi-state NovaSeq FASTQ files → **Output:** Continental population structure insights

*Transforming raw sequencing data into biological understanding of tick population dynamics across the United States*
