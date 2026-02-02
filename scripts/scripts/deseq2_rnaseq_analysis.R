# ============================================
# RNA-seq analysis using DESeq2
# Simulated data - 4 experimental groups
# ============================================

# Load libraries
library(DESeq2)
library(ggplot2)
library(pheatmap)
library(EnhancedVolcano)

set.seed(123)

# --------------------------------------------
# Simulate RNA-seq count data
# --------------------------------------------

n_genes <- 15000
n_samples <- 12

genes <- paste0("Gene_", 1:n_genes)

sample_info <- data.frame(
  sample = paste0("Sample_", 1:n_samples),
  genotype = rep(c("KO", "WT"), each = 6),
  diet = rep(c("NFD", "HFD"), times = 6)
)

sample_info$condition <- paste(sample_info$genotype, sample_info$diet, sep = "_")
rownames(sample_info) <- sample_info$sample

counts <- matrix(
  rnbinom(n_genes * n_samples, mu = 100, size = 1),
  ncol = n_samples
)

rownames(counts) <- genes
colnames(counts) <- sample_info$sample

# Introduce differential expression for KO_HFD
de_genes <- sample(genes, 400)

counts[de_genes, sample_info$condition == "KO_HFD"] <-
  counts[de_genes, sample_info$condition == "KO_HFD"] * 3

# --------------------------------------------
# DESeq2 analysis
# --------------------------------------------

dds <- DESeqDataSetFromMatrix(
  countData = counts,
  colData = sample_info,
  design = ~ genotype + diet + genotype:diet
)

dds <- DESeq(dds)

res <- results(dds)

# --------------------------------------------
# PCA
# --------------------------------------------

vsd <- vst(dds, blind = FALSE)

pca_plot <- plotPCA(vsd, intgroup = "condition") +
  theme_minimal()

ggsave("figures/PCA.png", pca_plot, width = 7, height = 5)

# --------------------------------------------
# Volcano plot
# --------------------------------------------

png("figures/volcano.png", width = 800, height = 700)
EnhancedVolcano(
  res,
  lab = rownames(res),
  x = "log2FoldChange",
  y = "pvalue",
  pCutoff = 0.05,
  FCcutoff = 1
)
dev.off()

# --------------------------------------------
# Heatmap of top genes
# --------------------------------------------

top_genes <- head(order(res$pvalue), 30)

png("figures/heatmap.png", width = 900, height = 800)
pheatmap(
  assay(vsd)[top_genes, ],
  cluster_rows = TRUE,
  cluster_cols = TRUE,
  annotation_col = sample_info["condition"]
)
dev.off()

# --------------------------------------------
# Save simulated data
# --------------------------------------------

write.csv(counts, "data/simulated_counts.csv")
write.csv(sample_info, "data/sample_metadata.csv")
