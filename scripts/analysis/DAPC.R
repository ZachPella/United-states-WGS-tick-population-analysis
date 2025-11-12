#### DAPC for R. megacantha reference-based datasets (filtered & thinned; no MAC) ####
####################################################################################
#### Interactive Start with all specimens dataset (K chosen manually) ####

# Load packages
library("adegenet")

# Set working directory
setwd("/work/fauverlab/zachpella/scripts_ticks_and_onlineJune2025/combined_pop_gen/structure_files")

# Read in data
cat("Reading structure file...\n")
data <- read.structure("filtered.iscap_fauver61andonline_gatksplitintervals10_snps_basefilt.maf01.miss20.mac2.bi.vcf.gz.LD_pruned.vcf.str_no_header_no_pop.str",
                       n.ind = 193,
                       n.loc = 1128099,
                       onerowperind = FALSE,
                       col.lab = 1,
                       col.pop = 0,
                       row.marknames = 0,
                       NA.char = "-9",
                       ask = FALSE) # <--- The crucial closing parenthesis is added here
cat("Data loaded successfully\n")

# ----------------------------------------------------------------------------------
# STEP 1: Find clusters - Save BIC plot
# ----------------------------------------------------------------------------------
cat("Running find.clusters...\n")

# Open PDF device BEFORE find.clusters to capture the BIC plot
pdf("step1_BIC_plot.pdf", width = 10, height = 8)
grp <- find.clusters(data,
                     max.n.clust = 192,
                     stat = c("BIC"))
dev.off()
cat("BIC plot saved to step1_BIC_plot.pdf\n")

# Set cluster count
grp$n.clust <- length(unique(grp$grp))
cat("Cluster count (K) set to:", grp$n.clust, "\n")

# NOTE: If find.clusters results in K=1, the script will fail later.
# Ensure you enter K=2 (or your desired number) when prompted during the interactive run.

# ----------------------------------------------------------------------------------
# STEP 2: Preliminary DAPC
# ----------------------------------------------------------------------------------
cat("Running preliminary DAPC...\n")
pdf("step2_prelim_dapc.pdf", width = 10, height = 8)
dapc.prelim <- dapc(data, grp$grp)
dev.off()
cat("Preliminary DAPC plot saved to step2_prelim_dapc.pdf\n")

# Save PCA/DAPC scatter plot after preliminary DAPC
cat("Generating PCA scatter plot from preliminary DAPC...\n")
pdf("step2_PCA_scatter.pdf", width = 10, height = 8)
scatter(dapc.prelim,
        scree.da = FALSE,
        bg = "white",
        pch = 20,
        cell = 0,
        cstar = 0,
        solid = 0.4,
        cex = 3,
        clab = 0,
        leg = TRUE,
        txt.leg = paste("Cluster", 1:grp$n.clust))
dev.off()
cat("PCA scatter plot saved to step2_PCA_scatter.pdf\n")

# ----------------------------------------------------------------------------------
# STEP 3: Optimize a-score
# ----------------------------------------------------------------------------------
cat("Optimizing a-score...\n")
pdf("step3_a_score_optimization.pdf", width = 10, height = 8)
temp <- optim.a.score(dapc.prelim)
dev.off()
cat("A-score optimization plot saved to step3_a_score_optimization.pdf\n")

# ----------------------------------------------------------------------------------
# STEP 4: Final DAPC
# ----------------------------------------------------------------------------------
cat("Running final DAPC...\n")
pdf("step4_final_dapc.pdf", width = 10, height = 8)
dapc <- dapc(data, grp$grp)
dev.off()
cat("Final DAPC plot saved to step4_final_dapc.pdf\n")

# Free memory
remove(dapc.prelim)
gc()

# ----------------------------------------------------------------------------------
# STEP 5: Save results and final scatter plot
# ----------------------------------------------------------------------------------
cat("Saving clustering results...\n")
clustering.key <- round(dapc$posterior, 3)
write.table(clustering.key,
            file = "clustering_key_Rm_refbased_allapples.DAPC.tsv",
            sep = "\t",
            row.names = TRUE,
            col.names = TRUE,
            quote = FALSE)

# Define custom colors
# Cluster 1: #AD122A (First in the list)
# Cluster 2: #129DBF (Second in the list)
custom_colors <- c("#AD122A", "#129DBF") # Order is for Cluster 1, Cluster 2, ...

cat("Generating final scatter plot...\n")
pdf("step5_DAPC_scatter_plot.pdf", width = 10, height = 8)
scatter(dapc,
        scree.da = FALSE,
        bg = "white",
        pch = 20,
        cell = 0,
        cstar = 0,
        solid = 0.4,
        cex = 3,
        clab = 0,
        leg = TRUE,
        txt.leg = paste("Cluster", 1:grp$n.clust),
        col = custom_colors[1:grp$n.clust]) # Apply custom colors
dev.off()

cat("\n===========================================\n")
cat("Analysis complete! Files saved:\n")
cat("  - step1_BIC_plot.pdf\n")
cat("  - step2_prelim_dapc.pdf\n")
cat("  - step2_PCA_scatter.pdf\n")
cat("  - step3_a_score_optimization.pdf\n")
cat("  - step4_final_dapc.pdf\n")
cat("  - step5_DAPC_scatter_plot.pdf\n")
cat("  - clustering_key_Rm_refbased_allapples.DAPC.tsv\n")
cat("===========================================\n")
