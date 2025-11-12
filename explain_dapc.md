# DAPC Analysis for *R. megacantha* Reference-Based Dataset

This repository contains an R script for performing Discriminant Analysis of Principal Components (DAPC) on *R. megacantha* genomic data.

## Overview

DAPC is a multivariate analysis method that identifies clusters of genetically related individuals and describes between-group genetic diversity. This script processes Structure-formatted genetic data through a complete DAPC workflow, from cluster identification to visualization.

## Requirements

### Software
- R (version 3.5 or higher recommended)
- RStudio (optional, but recommended)

### R Packages
```r
install.packages("adegenet")
```

## Input Data

The script expects a Structure-formatted file with the following specifications:

- **File name**: `cleaned_input_for_dapc.str`
- **Number of individuals**: 61
- **Number of loci**: 299,218
- **Format**: Two rows per individual
- **Missing data code**: -9
- **Column 1**: Individual labels
- **Column 2**: Population information (not used in this analysis)

## Workflow

The analysis follows five main steps:

### Step 1: Cluster Identification
- Uses `find.clusters()` to identify optimal number of clusters (K)
- Evaluates K values from 1 to 60
- Uses Bayesian Information Criterion (BIC) to select best K
- **Output**: `step1_BIC_plot.pdf`

### Step 2: Preliminary DAPC
- Performs initial DAPC analysis
- Generates PCA scatter plot showing cluster separation
- **Outputs**: 
  - `step2_prelim_dapc.pdf`
  - `step2_PCA_scatter.pdf`

### Step 3: A-score Optimization
- Optimizes the number of PCs to retain
- Balances discrimination power vs. overfitting
- **Output**: `step3_a_score_optimization.pdf`

### Step 4: Final DAPC
- Runs final DAPC with optimized parameters
- **Output**: `step4_final_dapc.pdf`

### Step 5: Results and Visualization
- Saves posterior membership probabilities for each individual
- Creates final scatter plot
- **Outputs**:
  - `step5_DAPC_scatter_plot.pdf`
  - `clustering_key_Rm_refbased_allapples.DAPC.tsv`

## Usage

### Basic Execution

1. Ensure your Structure file is in the working directory
2. Update the working directory path in the script:
```r
setwd("your/path/here")
```
3. Run the script in R:
```r
source("interactive_dapc.R")
```

### Interactive Elements

The script will prompt you to make several decisions during analysis. Here's what to expect:

**Step 1 - Cluster Identification:**
```
Choose the number PCs to retain (>= 1): 500
Choose the number of clusters (>=2): 2
```
- First, select PCs for cluster detection (e.g., 500 for large datasets)
- Then choose K (number of clusters) based on the BIC plot

**Step 2 - Preliminary DAPC:**
```
Choose the number PCs to retain (>=1): 60
Choose the number discriminant functions to retain (>=1): 1
```
- Select PCs for preliminary analysis (fewer than Step 1)
- Choose number of discriminant functions (usually K-1)

**Step 4 - Final DAPC:**
```
Choose the number PCs to retain (>=1): 1
Choose the number discriminant functions to retain (>=1): 1
```
- Use optimized values from Step 3's a-score plot
- This final run uses optimized parameters for best results

### Example Interactive Session

See `interactive_session.txt` for a complete example with K=2 clusters.

## Output Files

| File | Description |
|------|-------------|
| `step1_BIC_plot.pdf` | BIC values for different K values |
| `step2_prelim_dapc.pdf` | Preliminary DAPC results |
| `step2_PCA_scatter.pdf` | PCA scatter plot from preliminary analysis |
| `step3_a_score_optimization.pdf` | A-score optimization curve |
| `step4_final_dapc.pdf` | Final DAPC results |
| `step5_DAPC_scatter_plot.pdf` | Final scatter plot with optimized parameters |
| `clustering_key_Rm_refbased_allapples.DAPC.tsv` | Posterior membership probabilities (tab-delimited) |

## Interpreting Results

### BIC Plot (Step 1)
- Lower BIC values indicate better fit
- Look for the "elbow" point where BIC decreases sharply then levels off
- This suggests the optimal number of clusters

### Scatter Plots (Steps 2 & 5)
- Each point represents an individual
- Colors represent cluster assignments
- Distance between clusters indicates genetic differentiation
- Overlapping clusters suggest gene flow or recent divergence

### A-score Optimization (Step 3)
- Higher a-scores indicate better discrimination
- Peak of the curve shows optimal number of PCs
- Helps prevent overfitting while maintaining discrimination power

### Clustering Key
- Tab-delimited file with posterior probabilities
- Rows = individuals
- Columns = clusters
- Values = probability of membership (0-1)
- Values sum to 1 across each row

## Customization

### Modifying Cluster Range
Change the maximum number of clusters to test:
```r
grp <- find.clusters(data, max.n.clust = 60, stat = c("BIC"))
```

### Adjusting Plot Appearance
Modify scatter plot parameters:
```r
scatter(dapc,
        pch = 20,      # Point type
        cex = 3,       # Point size
        solid = 0.4)   # Transparency
```

## Troubleshooting

### Memory Issues
If you encounter memory errors:
```r
# Increase memory limit (Windows)
memory.limit(size = 50000)

# Or run garbage collection more frequently
gc()
```

### Missing Data
Ensure missing data is coded as `-9` in your Structure file.

### File Not Found Errors
Check that:
- Working directory is set correctly
- Input file name matches exactly
- File permissions allow reading

## Citation

If you use this script in your research, please cite:

- Jombart T, Devillard S, Balloux F (2010) Discriminant analysis of principal components: a new method for the analysis of genetically structured populations. *BMC Genetics* 11:94
- Jombart T (2008) adegenet: a R package for the multivariate analysis of genetic markers. *Bioinformatics* 24:1403-1405

## License

This script is provided as-is for research purposes.

## Contact

For questions or issues, please contact the repository maintainer.


K=2
<img width="763" height="613" alt="Screenshot 2025-10-28 152049" src="https://github.com/user-attachments/assets/a95dd700-230e-4776-bec7-b150f991ac80" />

<img width="771" height="611" alt="Screenshot 2025-10-28 152056" src="https://github.com/user-attachments/assets/88c0dc5a-4bd7-4508-88f1-32df7f174483" />

<img width="959" height="765" alt="Screenshot 2025-10-28 152105" src="https://github.com/user-attachments/assets/593484d7-5ec5-4d19-9d19-2b5d788b366f" />

<img width="957" height="763" alt="Screenshot 2025-10-28 152117" src="https://github.com/user-attachments/assets/42f521a9-b112-4f5c-8e8c-d0e05694c6f7" />

<img width="956" height="762" alt="Screenshot 2025-10-28 152123" src="https://github.com/user-attachments/assets/b89a4194-6041-4b23-85e9-642b19bd5b31" />

<img width="957" height="764" alt="Screenshot 2025-10-28 152130" src="https://github.com/user-attachments/assets/ae6a14b3-8eac-414a-ba7f-edeb56c09f5e" />

<img width="955" height="766" alt="Screenshot 2025-10-28 152138" src="https://github.com/user-attachments/assets/d0e10895-8043-4e71-8e60-459e767860f3" />

<img width="959" height="761" alt="Screenshot 2025-10-28 152144" src="https://github.com/user-attachments/assets/a46774b6-517f-4a47-aaec-3ff04fd3e50a" />

<img width="860" height="686" alt="Screenshot 2025-10-28 152150" src="https://github.com/user-attachments/assets/37dcc2d2-6cd8-4eba-8aca-583dc8e698da" />


--------------------------------------------------------------------------------------------------------------------------------------






K=3

<img width="959" height="767" alt="Screenshot 2025-10-28 152820" src="https://github.com/user-attachments/assets/61b3d14d-9fd9-4c1f-a136-ba054807f90c" />

<img width="959" height="763" alt="Screenshot 2025-10-28 152826" src="https://github.com/user-attachments/assets/d4ed7531-1c92-4c1a-8d9a-a0abb9379891" />

<img width="950" height="766" alt="Screenshot 2025-10-28 152832" src="https://github.com/user-attachments/assets/7f0b413a-70ee-462e-9c77-e18eae44e82f" />

<img width="962" height="768" alt="Screenshot 2025-10-28 152837" src="https://github.com/user-attachments/assets/c3c242ca-6b40-432b-ac51-f7aa58482167" />

<img width="957" height="766" alt="Screenshot 2025-10-28 152843" src="https://github.com/user-attachments/assets/8dfc4ff2-7b9b-4a4a-bc33-436b77db8af5" />

<img width="954" height="765" alt="Screenshot 2025-10-28 152847" src="https://github.com/user-attachments/assets/8cf057a6-c783-4e8e-bead-ebda49cfaa6c" />

<img width="962" height="766" alt="Screenshot 2025-10-28 152852" src="https://github.com/user-attachments/assets/8de98675-79f4-4810-b5bb-767505093ab4" />

<img width="953" height="769" alt="Screenshot 2025-10-28 152859" src="https://github.com/user-attachments/assets/fb362e93-71a3-48db-95d1-de7e8c6a6c87" />

<img width="960" height="766" alt="Screenshot 2025-10-28 152905" src="https://github.com/user-attachments/assets/461bf766-2630-49bc-88cc-59e8bae1f6e9" />
