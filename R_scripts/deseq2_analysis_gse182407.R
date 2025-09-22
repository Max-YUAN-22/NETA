#!/usr/bin/env Rscript

# GSE182407 DESeq2分析
# 作者: NETA团队
# 日期: 2024-01-15

# 加载必要的包
suppressPackageStartupMessages({
  library(DESeq2)
  library(ggplot2)
  library(pheatmap)
  library(RColorBrewer)
  library(limma)
})

# 设置工作目录
setwd("/Users/Apple/Desktop/pcatools/NETA")

# 创建输出目录
if (!dir.exists("data/processed/analysis_results/deseq2/GSE182407")) {
  dir.create("data/processed/analysis_results/deseq2/GSE182407", recursive = TRUE)
}

# 读取数据
read_gse182407_data <- function() {
  cat("=== 读取GSE182407数据 ===\n")
  
  # 读取表达矩阵
  expr_data <- read.csv("data/raw/GSE182407/GSE182407_expression_matrix_final.csv", 
                       row.names = 1, check.names = FALSE)
  
  # 读取表型数据
  pheno_data <- read.csv("data/raw/GSE182407/GSE182407_phenotype_data_final.csv", 
                        row.names = 1, check.names = FALSE)
  
  cat("表达矩阵维度:", dim(expr_data), "\n")
  cat("表型数据维度:", dim(pheno_data), "\n")
  
  # 检查数据
  cat("表达数据前几行:\n")
  print(head(expr_data[, 1:5]))
  
  cat("表型数据:\n")
  print(pheno_data)
  
  return(list(expr_data = expr_data, pheno_data = pheno_data))
}

# 进行DESeq2分析
perform_deseq2_analysis <- function(data_list) {
  cat("\n=== 进行DESeq2分析 ===\n")
  
  expr_data <- data_list$expr_data
  pheno_data <- data_list$pheno_data
  
  # 确保样本顺序一致
  common_samples <- intersect(colnames(expr_data), rownames(pheno_data))
  expr_data <- expr_data[, common_samples]
  pheno_data <- pheno_data[common_samples, ]
  
  cat("共同样本数:", length(common_samples), "\n")
  
  # 创建分组 - 只分析野生型vs YAP1干预
  groups <- ifelse(grepl("Control", pheno_data$group), "Control", "YAP1_intervention")
  pheno_data$comparison_group <- factor(groups)
  
  cat("比较分组:\n")
  print(table(pheno_data$comparison_group))
  
  # 创建DESeq2对象
  dds <- DESeqDataSetFromMatrix(
    countData = expr_data,
    colData = pheno_data,
    design = ~ comparison_group
  )
  
  # 过滤低表达基因
  dds <- dds[rowSums(counts(dds)) >= 10, ]
  cat("过滤后基因数:", nrow(dds), "\n")
  
  # 运行DESeq2
  dds <- DESeq(dds)
  
  # 获取结果
  results <- results(dds, contrast = c("comparison_group", "YAP1_intervention", "Control"))
  
  # 显著差异基因
  significant_genes <- subset(results, padj < 0.05 & !is.na(padj))
  
  cat("显著差异基因数:", nrow(significant_genes), "\n")
  cat("上调基因数:", sum(significant_genes$log2FoldChange > 0), "\n")
  cat("下调基因数:", sum(significant_genes$log2FoldChange < 0), "\n")
  
  # 保存结果
  output_dir <- "data/processed/analysis_results/deseq2/GSE182407"
  write.csv(results, file.path(output_dir, "deseq2_results.csv"), row.names = TRUE)
  write.csv(significant_genes, file.path(output_dir, "significant_genes.csv"), row.names = TRUE)
  
  # 生成图表
  generate_plots_deseq2(results, dds, output_dir)
  
  return(list(
    significant_genes_count = nrow(significant_genes),
    upregulated_count = sum(significant_genes$log2FoldChange > 0),
    downregulated_count = sum(significant_genes$log2FoldChange < 0),
    results = results,
    dds = dds
  ))
}

# 生成DESeq2图表
generate_plots_deseq2 <- function(results, dds, output_dir) {
  cat("生成DESeq2图表...\n")
  
  # 设置SCI一区质量的图表参数
  theme_sci <- theme_minimal() +
    theme(
      text = element_text(size = 12, family = "Arial"),
      axis.text = element_text(size = 10),
      axis.title = element_text(size = 12, face = "bold"),
      plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
      legend.text = element_text(size = 10),
      legend.title = element_text(size = 12, face = "bold"),
      panel.grid.major = element_line(color = "grey90", size = 0.5),
      panel.grid.minor = element_line(color = "grey95", size = 0.25)
    )
  
  # Volcano图
  png(file.path(output_dir, "volcano_plot.png"), width = 1000, height = 800, res = 300)
  volcano_data <- data.frame(
    log2FC = results$log2FoldChange,
    neg_log10_p = -log10(results$pvalue),
    significant = results$padj < 0.05 & !is.na(results$padj)
  )
  
  p <- ggplot(volcano_data, aes(x = log2FC, y = neg_log10_p, color = significant)) +
    geom_point(alpha = 0.6, size = 1) +
    scale_color_manual(values = c("FALSE" = "grey60", "TRUE" = "red")) +
    geom_hline(yintercept = -log10(0.05), linetype = "dashed", color = "black") +
    geom_vline(xintercept = c(-1, 1), linetype = "dashed", color = "black") +
    labs(
      title = "GSE182407 Volcano Plot",
      x = "Log2 Fold Change",
      y = "-Log10 P-value",
      color = "Significant"
    ) +
    theme_sci
  
  print(p)
  dev.off()
  
  # MA图
  png(file.path(output_dir, "ma_plot.png"), width = 1000, height = 800, res = 300)
  ma_data <- data.frame(
    baseMean = results$baseMean,
    log2FC = results$log2FoldChange,
    significant = results$padj < 0.05 & !is.na(results$padj)
  )
  
  p <- ggplot(ma_data, aes(x = baseMean, y = log2FC, color = significant)) +
    geom_point(alpha = 0.6, size = 1) +
    scale_color_manual(values = c("FALSE" = "grey60", "TRUE" = "red")) +
    geom_hline(yintercept = 0, linetype = "solid", color = "black") +
    labs(
      title = "GSE182407 MA Plot",
      x = "Base Mean",
      y = "Log2 Fold Change",
      color = "Significant"
    ) +
    theme_sci +
    scale_x_log10()
  
  print(p)
  dev.off()
  
  # PCA图
  png(file.path(output_dir, "pca_plot.png"), width = 1000, height = 800, res = 300)
  
  # 进行VST变换
  vsd <- varianceStabilizingTransformation(dds, blind = FALSE)
  
  # PCA分析
  pca_data <- prcomp(t(assay(vsd)))
  pca_df <- data.frame(
    PC1 = pca_data$x[, 1],
    PC2 = pca_data$x[, 2],
    group = colData(dds)$comparison_group,
    cell_line = colData(dds)$cell_line
  )
  
  p <- ggplot(pca_df, aes(x = PC1, y = PC2, color = group, shape = cell_line)) +
    geom_point(size = 3, alpha = 0.8) +
    labs(
      title = "GSE182407 PCA Plot",
      x = paste0("PC1 (", round(summary(pca_data)$importance[2,1]*100, 1), "%)"),
      y = paste0("PC2 (", round(summary(pca_data)$importance[2,2]*100, 1), "%)"),
      color = "Group",
      shape = "Cell Line"
    ) +
    theme_sci
  
  print(p)
  dev.off()
  
  # 热图
  png(file.path(output_dir, "heatmap.png"), width = 1200, height = 1000, res = 300)
  
  # 选择top 50显著差异基因
  top_genes <- head(order(results$padj, na.last = TRUE), 50)
  heatmap_data <- assay(vsd)[top_genes, ]
  
  # 创建注释
  annotation_col <- data.frame(
    Group = colData(dds)$comparison_group,
    CellLine = colData(dds)$cell_line
  )
  rownames(annotation_col) <- colnames(heatmap_data)
  
  pheatmap(
    heatmap_data,
    scale = "row",
    clustering_distance_rows = "correlation",
    clustering_distance_cols = "correlation",
    annotation_col = annotation_col,
    color = colorRampPalette(c("blue", "white", "red"))(100),
    main = "GSE182407 Top 50 Significant Genes Heatmap",
    fontsize = 8,
    fontsize_row = 6,
    fontsize_col = 8
  )
  
  dev.off()
  
  cat("✅ 图表生成完成\n")
}

# 主函数
main <- function() {
  cat("=== GSE182407 DESeq2分析开始 ===\n")
  
  # 读取数据
  data_list <- read_gse182407_data()
  
  # 进行DESeq2分析
  result <- perform_deseq2_analysis(data_list)
  
  if (!is.null(result)) {
    cat("\n=== 分析结果总结 ===\n")
    cat("显著差异基因数:", result$significant_genes_count, "\n")
    cat("上调基因数:", result$upregulated_count, "\n")
    cat("下调基因数:", result$downregulated_count, "\n")
    cat("✅ GSE182407 DESeq2分析完成！\n")
    
    # 显示top 10显著差异基因
    cat("\nTop 10显著差异基因:\n")
    top_genes <- head(order(result$results$padj, na.last = TRUE), 10)
    print(result$results[top_genes, c("log2FoldChange", "padj")])
  }
}

# 运行主函数
main()
