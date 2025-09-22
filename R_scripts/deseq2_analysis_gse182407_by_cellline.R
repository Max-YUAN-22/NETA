#!/usr/bin/env Rscript

# GSE182407 DESeq2分析 - 按细胞系分组
# 作者: NETA团队
# 日期: 2024-01-15

# 加载必要的包
suppressPackageStartupMessages({
  library(DESeq2)
  library(ggplot2)
  library(pheatmap)
  library(RColorBrewer)
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
  
  return(list(expr_data = expr_data, pheno_data = pheno_data))
}

# 按细胞系进行分析
analyze_by_cell_line <- function(data_list) {
  cat("\n=== 按细胞系进行DESeq2分析 ===\n")
  
  expr_data <- data_list$expr_data
  pheno_data <- data_list$pheno_data
  
  # 获取所有细胞系
  cell_lines <- unique(pheno_data$cell_line)
  cat("细胞系:", paste(cell_lines, collapse = ", "), "\n")
  
  all_results <- list()
  
  for (cell_line in cell_lines) {
    cat("\n--- 分析", cell_line, "---\n")
    
    # 筛选当前细胞系的样本
    cell_line_samples <- rownames(pheno_data)[pheno_data$cell_line == cell_line]
    cat("样本数:", length(cell_line_samples), "\n")
    
    if (length(cell_line_samples) < 4) {
      cat("❌", cell_line, "样本数不足，跳过\n")
      next
    }
    
    # 筛选表达数据
    cell_line_expr <- expr_data[, cell_line_samples]
    cell_line_pheno <- pheno_data[cell_line_samples, ]
    
    # 创建分组
    groups <- ifelse(grepl("Control", cell_line_pheno$group), "Control", "YAP1_intervention")
    cell_line_pheno$comparison_group <- factor(groups)
    
    cat("分组情况:\n")
    print(table(cell_line_pheno$comparison_group))
    
    # 检查是否有足够的样本进行对比
    if (length(unique(groups)) < 2 || min(table(groups)) < 2) {
      cat("❌", cell_line, "分组不足，跳过\n")
      next
    }
    
    # 创建DESeq2对象
    dds <- DESeqDataSetFromMatrix(
      countData = cell_line_expr,
      colData = cell_line_pheno,
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
    write.csv(results, file.path(output_dir, paste0("deseq2_results_", cell_line, ".csv")), row.names = TRUE)
    write.csv(significant_genes, file.path(output_dir, paste0("significant_genes_", cell_line, ".csv")), row.names = TRUE)
    
    # 生成图表
    generate_plots_cell_line(results, dds, output_dir, cell_line)
    
    all_results[[cell_line]] <- list(
      significant_genes_count = nrow(significant_genes),
      upregulated_count = sum(significant_genes$log2FoldChange > 0),
      downregulated_count = sum(significant_genes$log2FoldChange < 0),
      results = results,
      dds = dds
    )
  }
  
  return(all_results)
}

# 生成细胞系特异性图表
generate_plots_cell_line <- function(results, dds, output_dir, cell_line) {
  cat("生成", cell_line, "图表...\n")
  
  # 设置SCI一区质量的图表参数
  theme_sci <- theme_minimal() +
    theme(
      text = element_text(size = 12, family = "Arial"),
      axis.text = element_text(size = 10),
      axis.title = element_text(size = 12, face = "bold"),
      plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
      legend.text = element_text(size = 10),
      legend.title = element_text(size = 12, face = "bold"),
      panel.grid.major = element_line(color = "grey90", linewidth = 0.5),
      panel.grid.minor = element_line(color = "grey95", linewidth = 0.25)
    )
  
  # Volcano图
  png(file.path(output_dir, paste0("volcano_plot_", cell_line, ".png")), width = 1000, height = 800, res = 300)
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
      title = paste0("GSE182407 ", cell_line, " Volcano Plot"),
      x = "Log2 Fold Change",
      y = "-Log10 P-value",
      color = "Significant"
    ) +
    theme_sci
  
  print(p)
  dev.off()
  
  # MA图
  png(file.path(output_dir, paste0("ma_plot_", cell_line, ".png")), width = 1000, height = 800, res = 300)
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
      title = paste0("GSE182407 ", cell_line, " MA Plot"),
      x = "Base Mean",
      y = "Log2 Fold Change",
      color = "Significant"
    ) +
    theme_sci +
    scale_x_log10()
  
  print(p)
  dev.off()
  
  # PCA图
  png(file.path(output_dir, paste0("pca_plot_", cell_line, ".png")), width = 1000, height = 800, res = 300)
  
  # 进行VST变换
  vsd <- varianceStabilizingTransformation(dds, blind = FALSE)
  
  # PCA分析
  pca_data <- prcomp(t(assay(vsd)))
  pca_df <- data.frame(
    PC1 = pca_data$x[, 1],
    PC2 = pca_data$x[, 2],
    group = colData(dds)$comparison_group
  )
  
  p <- ggplot(pca_df, aes(x = PC1, y = PC2, color = group)) +
    geom_point(size = 3, alpha = 0.8) +
    labs(
      title = paste0("GSE182407 ", cell_line, " PCA Plot"),
      x = paste0("PC1 (", round(summary(pca_data)$importance[2,1]*100, 1), "%)"),
      y = paste0("PC2 (", round(summary(pca_data)$importance[2,2]*100, 1), "%)"),
      color = "Group"
    ) +
    theme_sci
  
  print(p)
  dev.off()
  
  cat("✅", cell_line, "图表生成完成\n")
}

# 主函数
main <- function() {
  cat("=== GSE182407按细胞系DESeq2分析开始 ===\n")
  
  # 读取数据
  data_list <- read_gse182407_data()
  
  # 按细胞系进行分析
  all_results <- analyze_by_cell_line(data_list)
  
  if (length(all_results) > 0) {
    cat("\n=== 分析结果总结 ===\n")
    for (cell_line in names(all_results)) {
      result <- all_results[[cell_line]]
      cat("\n", cell_line, ":\n")
      cat("  显著差异基因数:", result$significant_genes_count, "\n")
      cat("  上调基因数:", result$upregulated_count, "\n")
      cat("  下调基因数:", result$downregulated_count, "\n")
      
      if (result$significant_genes_count > 0) {
        cat("  Top 5显著差异基因:\n")
        top_genes <- head(order(result$results$padj, na.last = TRUE), 5)
        print(result$results[top_genes, c("log2FoldChange", "padj")])
      }
    }
    cat("\n✅ GSE182407按细胞系DESeq2分析完成！\n")
  } else {
    cat("\n❌ 没有成功分析任何细胞系\n")
  }
}

# 运行主函数
main()
