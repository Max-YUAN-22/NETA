#!/usr/bin/env Rscript

# 批量DESeq2分析 - 所有15个NETA数据集
# 生成SCI一区质量的图表和结果
# 作者: NETA团队
# 日期: 2024-01-15

# 加载必要的包
suppressPackageStartupMessages({
  library(DESeq2)
  library(ggplot2)
  library(pheatmap)
  library(RColorBrewer)
  library(dplyr)
  library(readr)
})

# 设置工作目录
setwd("/Users/Apple/Desktop/pcatools/NETA")

# 创建输出目录
if (!dir.exists("data/processed/analysis_results/deseq2")) {
  dir.create("data/processed/analysis_results/deseq2", recursive = TRUE)
}

# 所有15个数据集列表
datasets <- c(
  "GSE73338", "GSE98894", "GSE103174", "GSE117851", "GSE156405",
  "GSE11969", "GSE60436", "GSE126030", "GSE165552", "GSE10245",
  "GSE19830", "GSE30554", "GSE59739", "GSE60361", "GSE71585"
)

# SCI一区期刊主题
sci_theme <- theme_minimal() +
  theme(
    text = element_text(size = 12, family = "Arial"),
    axis.text = element_text(size = 10),
    axis.title = element_text(size = 12, face = "bold"),
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
    legend.text = element_text(size = 10),
    legend.title = element_text(size = 11, face = "bold"),
    panel.grid.major = element_line(color = "grey90", size = 0.5),
    panel.grid.minor = element_line(color = "grey95", size = 0.25),
    strip.text = element_text(size = 11, face = "bold")
  )

# DESeq2分析函数
run_deseq2_analysis <- function(geo_id) {
  cat("开始分析数据集:", geo_id, "\n")
  
  tryCatch({
    # 读取数据
    expr_file <- paste0("data/raw/", geo_id, "_expression_matrix.csv")
    pheno_file <- paste0("data/raw/", geo_id, "_phenotype_data.csv")
    
    if (!file.exists(expr_file) || !file.exists(pheno_file)) {
      cat("❌", geo_id, "数据文件不存在\n")
      return(FALSE)
    }
    
    # 读取表达矩阵
    expr_data <- read.csv(expr_file, row.names = 1, check.names = FALSE)
    cat("  - 表达矩阵:", nrow(expr_data), "基因 x", ncol(expr_data), "样本\n")
    
    # 读取表型数据
    pheno_data <- read.csv(pheno_file, row.names = 1, check.names = FALSE)
    cat("  - 表型数据:", nrow(pheno_data), "样本\n")
    
    # 数据预处理
    # 确保样本名称一致
    common_samples <- intersect(colnames(expr_data), rownames(pheno_data))
    if (length(common_samples) < 3) {
      cat("❌", geo_id, "样本数不足，跳过分析\n")
      return(FALSE)
    }
    
    expr_data <- expr_data[, common_samples]
    pheno_data <- pheno_data[common_samples, ]
    
    # 创建分组变量
    # 尝试从表型数据中提取分组信息
    group_col <- NULL
    for (col in colnames(pheno_data)) {
      if (grepl("group|condition|treatment|disease|type", col, ignore.case = TRUE)) {
        group_col <- col
        break
      }
    }
    
    if (is.null(group_col)) {
      # 如果没有找到分组列，尝试从样本名称推断
      sample_names <- rownames(pheno_data)
      if (any(grepl("control|normal", sample_names, ignore.case = TRUE))) {
        groups <- ifelse(grepl("control|normal", sample_names, ignore.case = TRUE), "Control", "Case")
      } else {
        # 简单分为两组
        groups <- rep(c("Group1", "Group2"), length.out = length(sample_names))
      }
    } else {
      groups <- as.character(pheno_data[[group_col]])
    }
    
    # 确保有足够的样本
    if (length(unique(groups)) < 2 || min(table(groups)) < 2) {
      cat("❌", geo_id, "分组信息不足，跳过分析\n")
      return(FALSE)
    }
    
    cat("  - 分组:", paste(unique(groups), collapse = " vs "), "\n")
    cat("  - 样本数:", paste(table(groups), collapse = ", "), "\n")
    
    # 创建DESeq2对象
    col_data <- data.frame(
      sample_id = rownames(pheno_data),
      group = factor(groups),
      row.names = rownames(pheno_data)
    )
    
    # 过滤低表达基因
    keep <- rowSums(expr_data >= 10) >= 3
    expr_data_filtered <- expr_data[keep, ]
    cat("  - 过滤后基因数:", nrow(expr_data_filtered), "\n")
    
    # 创建DESeq2数据集
    dds <- DESeqDataSetFromMatrix(
      countData = round(expr_data_filtered),
      colData = col_data,
      design = ~ group
    )
    
    # 运行DESeq2分析
    cat("  - 运行DESeq2分析...\n")
    dds <- DESeq(dds)
    
    # 获取结果
    res <- results(dds, alpha = 0.05)
    res <- res[order(res$padj), ]
    
    # 过滤显著基因
    sig_genes <- res[!is.na(res$padj) & res$padj < 0.05 & abs(res$log2FoldChange) > 1, ]
    cat("  - 显著差异基因:", nrow(sig_genes), "\n")
    
    # 创建输出目录
    output_dir <- paste0("data/processed/analysis_results/deseq2/", geo_id)
    if (!dir.exists(output_dir)) {
      dir.create(output_dir, recursive = TRUE)
    }
    
    # 1. 火山图
    volcano_data <- data.frame(
      gene = rownames(res),
      log2FC = res$log2FoldChange,
      pvalue = -log10(res$pvalue),
      padj = res$padj,
      significant = !is.na(res$padj) & res$padj < 0.05 & abs(res$log2FoldChange) > 1
    )
    
    png(paste0(output_dir, "/volcano_plot.png"), width = 800, height = 600, res = 300)
    p <- ggplot(volcano_data, aes(x = log2FC, y = pvalue, color = significant)) +
      geom_point(alpha = 0.6, size = 1) +
      scale_color_manual(values = c("FALSE" = "grey60", "TRUE" = "red")) +
      labs(
        title = paste0("Volcano Plot - ", geo_id),
        x = "Log2 Fold Change",
        y = "-Log10 P-value"
      ) +
      sci_theme +
      theme(legend.position = "none")
    print(p)
    dev.off()
    
    # 2. MA图
    png(paste0(output_dir, "/ma_plot.png"), width = 800, height = 600, res = 300)
    plotMA(res, main = paste0("MA Plot - ", geo_id))
    dev.off()
    
    # 3. PCA图
    vsd <- varianceStabilizingTransformation(dds, blind = FALSE)
    pca_data <- plotPCA(vsd, intgroup = "group", returnData = TRUE)
    
    png(paste0(output_dir, "/pca_plot.png"), width = 800, height = 600, res = 300)
    p <- ggplot(pca_data, aes(x = PC1, y = PC2, color = group)) +
      geom_point(size = 3, alpha = 0.8) +
      labs(
        title = paste0("PCA Plot - ", geo_id),
        x = paste0("PC1: ", round(attr(pca_data, "percentVar")[1] * 100), "% variance"),
        y = paste0("PC2: ", round(attr(pca_data, "percentVar")[2] * 100), "% variance")
      ) +
      sci_theme +
      theme(legend.position = "bottom")
    print(p)
    dev.off()
    
    # 4. 热图
    if (nrow(sig_genes) > 0) {
      # 选择top 50显著基因
      top_genes <- head(rownames(sig_genes), 50)
      heatmap_data <- assay(vsd)[top_genes, ]
      
      png(paste0(output_dir, "/heatmap.png"), width = 1000, height = 800, res = 300)
      pheatmap(
        heatmap_data,
        scale = "row",
        clustering_distance_rows = "correlation",
        clustering_distance_cols = "correlation",
        color = colorRampPalette(c("blue", "white", "red"))(100),
        main = paste0("Heatmap - Top 50 Significant Genes - ", geo_id),
        fontsize = 8
      )
      dev.off()
    }
    
    # 5. 保存结果
    write.csv(as.data.frame(res), file = paste0(output_dir, "/deseq2_results.csv"))
    write.csv(as.data.frame(sig_genes), file = paste0(output_dir, "/significant_genes.csv"))
    
    # 6. 生成统计报告
    stats <- list(
      dataset = geo_id,
      total_genes = nrow(expr_data),
      filtered_genes = nrow(expr_data_filtered),
      total_samples = ncol(expr_data),
      groups = unique(groups),
      group_sizes = table(groups),
      significant_genes = nrow(sig_genes),
      upregulated = sum(sig_genes$log2FoldChange > 1, na.rm = TRUE),
      downregulated = sum(sig_genes$log2FoldChange < -1, na.rm = TRUE)
    )
    
    writeLines(
      paste0(names(stats), ": ", stats),
      paste0(output_dir, "/analysis_summary.txt")
    )
    
    cat("✅", geo_id, "分析完成\n")
    cat("  - 输出目录:", output_dir, "\n")
    cat("  - 显著基因:", nrow(sig_genes), "\n")
    cat("  - 上调基因:", sum(sig_genes$log2FoldChange > 1, na.rm = TRUE), "\n")
    cat("  - 下调基因:", sum(sig_genes$log2FoldChange < -1, na.rm = TRUE), "\n\n")
    
    return(TRUE)
    
  }, error = function(e) {
    cat("❌", geo_id, "分析失败:", e$message, "\n\n")
    return(FALSE)
  })
}

# 批量分析所有数据集
cat("=== 开始批量DESeq2分析 ===\n")
cat("数据集列表:", paste(datasets, collapse = ", "), "\n")
cat("总数据集数:", length(datasets), "\n\n")

success_count <- 0
failed_datasets <- c()

for (geo_id in datasets) {
  if (run_deseq2_analysis(geo_id)) {
    success_count <- success_count + 1
  } else {
    failed_datasets <- c(failed_datasets, geo_id)
  }
}

# 总结
cat("=== 分析完成 ===\n")
cat("成功分析:", success_count, "个数据集\n")
cat("失败数据集:", length(failed_datasets), "个\n")

if (length(failed_datasets) > 0) {
  cat("失败的数据集:", paste(failed_datasets, collapse = ", "), "\n")
}

cat("\n所有结果已保存到 data/processed/analysis_results/deseq2/ 目录\n")
cat("下一步: 更新前端链接\n")
