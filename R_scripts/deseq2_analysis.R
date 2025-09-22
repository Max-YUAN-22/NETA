#!/usr/bin/env Rscript

# NETA DESeq2差异表达分析脚本
# 作者: NETA项目组
# 功能: 对神经内分泌肿瘤RNA-seq数据进行DESeq2差异表达分析

# 加载必要的包
suppressPackageStartupMessages({
  library(DESeq2)
  library(ggplot2)
  library(pheatmap)
  library(VennDiagram)
  library(EnhancedVolcano)
  library(dplyr)
  library(readr)
  library(tidyr)
})

# 设置工作目录
setwd("/Users/Apple/Desktop/pcatools/NETA")

# 创建输出目录
if (!dir.exists("data/processed/analysis_results/deseq2")) {
  dir.create("data/processed/analysis_results/deseq2", recursive = TRUE)
}

# DESeq2分析函数
run_deseq2_analysis <- function(dataset_id, comparison_groups = NULL) {
  cat("开始DESeq2分析:", dataset_id, "\n")
  
  # 读取数据
  expr_file <- paste0("data/raw/", dataset_id, "/expression_matrix.csv")
  pheno_file <- paste0("data/raw/", dataset_id, "/phenotype_data.csv")
  
  if (!file.exists(expr_file) || !file.exists(pheno_file)) {
    cat("警告: 数据文件不存在", dataset_id, "\n")
    return(NULL)
  }
  
  # 读取表达矩阵
  expr_matrix <- read_csv(expr_file, show_col_types = FALSE)
  expr_matrix <- as.data.frame(expr_matrix)
  rownames(expr_matrix) <- expr_matrix[,1]
  expr_matrix <- expr_matrix[,-1]
  
  # 读取表型数据
  pheno_data <- read_csv(pheno_file, show_col_types = FALSE)
  pheno_data <- as.data.frame(pheno_data)
  
  # 确保样本名匹配
  common_samples <- intersect(colnames(expr_matrix), pheno_data$sample_id)
  if (length(common_samples) < 3) {
    cat("警告: 样本数不足", dataset_id, "\n")
    return(NULL)
  }
  
  expr_matrix <- expr_matrix[, common_samples]
  pheno_data <- pheno_data[pheno_data$sample_id %in% common_samples, ]
  
  # 转换为整数矩阵
  expr_matrix <- round(expr_matrix)
  expr_matrix[expr_matrix < 0] <- 0
  
  # 过滤低表达基因
  keep <- rowSums(expr_matrix >= 10) >= 3
  expr_matrix <- expr_matrix[keep, ]
  
  cat("过滤后基因数:", nrow(expr_matrix), "\n")
  cat("样本数:", ncol(expr_matrix), "\n")
  
  # 创建DESeq2对象
  dds <- DESeqDataSetFromMatrix(
    countData = expr_matrix,
    colData = pheno_data,
    design = ~ group
  )
  
  # 运行DESeq2分析
  dds <- DESeq(dds)
  
  # 获取结果
  res <- results(dds)
  res <- res[order(res$padj), ]
  
  # 添加基因名
  res$gene_id <- rownames(res)
  
  # 保存结果
  output_dir <- paste0("data/processed/analysis_results/deseq2/", dataset_id)
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }
  
  # 保存完整结果
  write_csv(as.data.frame(res), paste0(output_dir, "/deseq2_results.csv"))
  
  # 保存显著差异基因
  sig_genes <- res[!is.na(res$padj) & res$padj < 0.05 & abs(res$log2FoldChange) > 1, ]
  write_csv(as.data.frame(sig_genes), paste0(output_dir, "/significant_genes.csv"))
  
  # 创建可视化
  create_deseq2_plots(dds, res, output_dir)
  
  cat("DESeq2分析完成:", dataset_id, "\n")
  return(list(dds = dds, results = res, significant_genes = sig_genes))
}

# 创建DESeq2可视化图表
create_deseq2_plots <- function(dds, res, output_dir) {
  
  # 1. MA图
  png(paste0(output_dir, "/ma_plot.png"), width = 800, height = 600)
  plotMA(res, main = "MA Plot")
  dev.off()
  
  # 2. 火山图
  png(paste0(output_dir, "/volcano_plot.png"), width = 800, height = 600)
  plot(res$log2FoldChange, -log10(res$padj), 
       pch = 20, cex = 0.6,
       xlab = "Log2 Fold Change", 
       ylab = "-Log10 P-value",
       main = "Volcano Plot")
  abline(h = -log10(0.05), col = "red", lty = 2)
  abline(v = c(-1, 1), col = "red", lty = 2)
  dev.off()
  
  # 3. 热图 - 前20个差异基因
  if (nrow(res) > 0) {
    top_genes <- head(res[order(res$padj), ], 20)
    if (nrow(top_genes) > 0) {
      # 获取标准化计数
      vsd <- vst(dds, blind = FALSE)
      top_counts <- assay(vsd)[rownames(top_genes), ]
      
      png(paste0(output_dir, "/heatmap_top20.png"), width = 1000, height = 800)
      pheatmap(top_counts, 
               scale = "row",
               clustering_distance_rows = "correlation",
               clustering_distance_cols = "correlation",
               main = "Top 20 Differentially Expressed Genes")
      dev.off()
    }
  }
  
  # 4. 样本聚类图
  vsd <- vst(dds, blind = FALSE)
  sampleDists <- dist(t(assay(vsd)))
  sampleDistMatrix <- as.matrix(sampleDists)
  
  png(paste0(output_dir, "/sample_clustering.png"), width = 800, height = 600)
  pheatmap(sampleDistMatrix,
           clustering_distance_rows = sampleDists,
           clustering_distance_cols = sampleDists,
           main = "Sample Clustering")
  dev.off()
  
  # 5. PCA图
  pca_data <- plotPCA(vsd, intgroup = "group", returnData = TRUE)
  
  png(paste0(output_dir, "/pca_plot.png"), width = 800, height = 600)
  ggplot(pca_data, aes(x = PC1, y = PC2, color = group)) +
    geom_point(size = 3) +
    labs(title = "PCA Plot", 
         x = paste0("PC1: ", round(attr(pca_data, "percentVar")[1] * 100), "% variance"),
         y = paste0("PC2: ", round(attr(pca_data, "percentVar")[2] * 100), "% variance")) +
    theme_minimal()
  dev.off()
}

# 批量分析所有数据集
batch_deseq2_analysis <- function() {
  datasets <- c("GSE73338", "GSE98894", "GSE103174", "GSE117851", 
                "GSE156405", "GSE11969", "GSE60436", "GSE126030")
  
  results <- list()
  
  for (dataset in datasets) {
    cat("\n=== 分析数据集:", dataset, "===\n")
    result <- run_deseq2_analysis(dataset)
    if (!is.null(result)) {
      results[[dataset]] <- result
    }
  }
  
  # 创建汇总报告
  create_summary_report(results)
  
  return(results)
}

# 创建汇总报告
create_summary_report <- function(results) {
  cat("\n=== 创建汇总报告 ===\n")
  
  summary_data <- data.frame(
    Dataset = character(),
    Total_Genes = integer(),
    Significant_Genes = integer(),
    Upregulated = integer(),
    Downregulated = integer(),
    stringsAsFactors = FALSE
  )
  
  for (dataset in names(results)) {
    res <- results[[dataset]]$results
    sig_genes <- res[!is.na(res$padj) & res$padj < 0.05 & abs(res$log2FoldChange) > 1, ]
    
    up_genes <- sum(sig_genes$log2FoldChange > 1, na.rm = TRUE)
    down_genes <- sum(sig_genes$log2FoldChange < -1, na.rm = TRUE)
    
    summary_data <- rbind(summary_data, data.frame(
      Dataset = dataset,
      Total_Genes = nrow(res),
      Significant_Genes = nrow(sig_genes),
      Upregulated = up_genes,
      Downregulated = down_genes
    ))
  }
  
  # 保存汇总报告
  write_csv(summary_data, "data/processed/analysis_results/deseq2/summary_report.csv")
  
  # 创建汇总可视化
  png("data/processed/analysis_results/deseq2/summary_plot.png", width = 1200, height = 800)
  par(mfrow = c(2, 2))
  
  # 显著基因数量
  barplot(summary_data$Significant_Genes, 
          names.arg = summary_data$Dataset,
          main = "Significant Genes per Dataset",
          ylab = "Number of Genes",
          las = 2)
  
  # 上调vs下调基因
  barplot(t(as.matrix(summary_data[, c("Upregulated", "Downregulated")])),
          names.arg = summary_data$Dataset,
          main = "Upregulated vs Downregulated Genes",
          ylab = "Number of Genes",
          las = 2,
          legend.text = c("Upregulated", "Downregulated"),
          beside = TRUE)
  
  # 总基因数
  barplot(summary_data$Total_Genes,
          names.arg = summary_data$Dataset,
          main = "Total Genes per Dataset",
          ylab = "Number of Genes",
          las = 2)
  
  # 显著基因比例
  sig_ratio <- summary_data$Significant_Genes / summary_data$Total_Genes * 100
  barplot(sig_ratio,
          names.arg = summary_data$Dataset,
          main = "Significant Genes Ratio (%)",
          ylab = "Percentage",
          las = 2)
  
  dev.off()
  
  cat("汇总报告已保存到: data/processed/analysis_results/deseq2/\n")
}

# 主函数
main <- function() {
  cat("=== NETA DESeq2差异表达分析 ===\n")
  cat("开始时间:", Sys.time(), "\n")
  
  # 检查R包
  required_packages <- c("DESeq2", "ggplot2", "pheatmap", "VennDiagram", 
                        "EnhancedVolcano", "dplyr", "readr", "tidyr")
  
  missing_packages <- required_packages[!sapply(required_packages, requireNamespace, quietly = TRUE)]
  
  if (length(missing_packages) > 0) {
    cat("安装缺失的R包:", paste(missing_packages, collapse = ", "), "\n")
    install.packages(missing_packages, repos = "https://cran.rstudio.com/")
  }
  
  # 运行批量分析
  results <- batch_deseq2_analysis()
  
  cat("分析完成时间:", Sys.time(), "\n")
  cat("结果保存在: data/processed/analysis_results/deseq2/\n")
  
  return(results)
}

# 如果直接运行脚本
if (!interactive()) {
  main()
}
