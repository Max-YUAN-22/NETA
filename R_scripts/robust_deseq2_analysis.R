#!/usr/bin/env Rscript

# 强大的DESeq2分析 - 处理各种数据问题
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

# SCI一区期刊主题
sci_theme <- theme_minimal() +
  theme(
    text = element_text(size = 12, family = "Arial"),
    axis.text = element_text(size = 10),
    axis.title = element_text(size = 12, face = "bold"),
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
    legend.text = element_text(size = 10),
    legend.title = element_text(size = 11, face = "bold"),
    panel.grid.major = element_line(color = "grey90", linewidth = 0.5),
    panel.grid.minor = element_line(color = "grey95", linewidth = 0.25),
    strip.text = element_text(size = 11, face = "bold")
  )

# 智能分组提取函数
extract_groups <- function(pheno_data, geo_id) {
  cat("  - 分析表型数据列:", paste(colnames(pheno_data), collapse = ", "), "\n")
  
  groups <- NULL
  
  # 策略1: 从source_name_ch1提取
  if ("source_name_ch1" %in% colnames(pheno_data)) {
    source_names <- as.character(pheno_data$source_name_ch1)
    cat("  - source_name_ch1:", paste(unique(source_names), collapse = ", "), "\n")
    
    # 清理和标准化分组名称
    groups <- gsub(".*: ", "", source_names)
    groups <- gsub("\\s+", "_", groups)
    groups <- gsub("[^A-Za-z0-9_]", "", groups)
    
    # 进一步清理
    groups <- gsub("Non_functional_PanNET", "Non_functional", groups)
    groups <- gsub("Insulinoma", "Insulinoma", groups)
    groups <- gsub("Gastrinoma", "Gastrinoma", groups)
    groups <- gsub("Glucagonoma", "Glucagonoma", groups)
    groups <- gsub("VIPoma", "VIPoma", groups)
    groups <- gsub("Somatostatinoma", "Somatostatinoma", groups)
    groups <- gsub("Normal_pancreas", "Normal", groups)
    groups <- gsub("Normal_pancreas_islet", "Normal", groups)
    groups <- gsub("Functional", "Functional", groups)
    groups <- gsub("Metastases", "Metastases", groups)
    groups <- gsub("Primary_lung_tumor", "Tumor", groups)
    groups <- gsub("Normal_lung_tissue", "Normal", groups)
    groups <- gsub("fresh_lung_tissue", "Lung_tissue", groups)
    groups <- gsub("human_non_small_cell_lung_cancer_tumor_tissue", "Tumor", groups)
  }
  
  # 策略2: 从title列提取
  if (is.null(groups) && "title" %in% colnames(pheno_data)) {
    titles <- as.character(pheno_data$title)
    cat("  - title:", paste(unique(titles), collapse = ", "), "\n")
    
    groups <- sapply(titles, function(x) {
      if (grepl("Non-functional", x, ignore.case = TRUE)) return("Non_functional")
      if (grepl("Insulinoma", x, ignore.case = TRUE)) return("Insulinoma")
      if (grepl("Gastrinoma", x, ignore.case = TRUE)) return("Gastrinoma")
      if (grepl("Glucagonoma", x, ignore.case = TRUE)) return("Glucagonoma")
      if (grepl("VIPoma", x, ignore.case = TRUE)) return("VIPoma")
      if (grepl("Somatostatinoma", x, ignore.case = TRUE)) return("Somatostatinoma")
      if (grepl("Control", x, ignore.case = TRUE)) return("Control")
      if (grepl("Normal", x, ignore.case = TRUE)) return("Normal")
      return("Other")
    })
  }
  
  # 策略3: 从characteristics_ch1提取
  if (is.null(groups) && "characteristics_ch1" %in% colnames(pheno_data)) {
    characteristics <- as.character(pheno_data$characteristics_ch1)
    cat("  - characteristics_ch1:", paste(unique(characteristics), collapse = ", "), "\n")
    
    groups <- sapply(characteristics, function(x) {
      if (grepl("control", x, ignore.case = TRUE)) return("Control")
      if (grepl("normal", x, ignore.case = TRUE)) return("Normal")
      if (grepl("tumor", x, ignore.case = TRUE)) return("Tumor")
      return("Other")
    })
  }
  
  # 策略4: 从样本名称推断
  if (is.null(groups)) {
    sample_names <- rownames(pheno_data)
    cat("  - 从样本名称推断分组\n")
    
    groups <- sapply(sample_names, function(x) {
      if (grepl("control|normal", x, ignore.case = TRUE)) return("Control")
      if (grepl("tumor|case", x, ignore.case = TRUE)) return("Tumor")
      return("Other")
    })
  }
  
  # 如果仍然没有分组，创建简单分组
  if (is.null(groups)) {
    cat("  - 创建简单分组\n")
    groups <- rep(c("Group1", "Group2"), length.out = nrow(pheno_data))
  }
  
  return(groups)
}

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
    
    # 检查数据类型
    if (!is.numeric(as.matrix(expr_data))) {
      cat("  - 转换数据类型为数值型\n")
      expr_data <- apply(expr_data, 2, as.numeric)
      rownames(expr_data) <- rownames(read.csv(expr_file, row.names = 1, check.names = FALSE))
    }
    
    # 读取表型数据
    pheno_data <- read.csv(pheno_file, row.names = 1, check.names = FALSE)
    cat("  - 表型数据:", nrow(pheno_data), "样本\n")
    
    # 数据预处理
    # 确保样本名称一致
    common_samples <- intersect(colnames(expr_data), rownames(pheno_data))
    if (length(common_samples) < 6) {
      cat("❌", geo_id, "样本数不足，跳过分析\n")
      return(FALSE)
    }
    
    expr_data <- expr_data[, common_samples]
    pheno_data <- pheno_data[common_samples, ]
    
    # 提取分组信息
    groups <- extract_groups(pheno_data, geo_id)
    
    # 确保有足够的样本
    if (length(unique(groups)) < 2 || min(table(groups)) < 3) {
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
    
    if (nrow(expr_data_filtered) < 100) {
      cat("❌", geo_id, "过滤后基因数不足，跳过分析\n")
      return(FALSE)
    }
    
    # 创建DESeq2数据集
    dds <- DESeqDataSetFromMatrix(
      countData = round(expr_data_filtered),
      colData = col_data,
      design = ~ group
    )
    
    # 运行DESeq2分析
    cat("  - 运行DESeq2分析...\n")
    
    # 尝试标准分析
    tryCatch({
      dds <- DESeq(dds)
    }, error = function(e) {
      cat("  - 标准分析失败，尝试替代方法\n")
      # 使用基因特异性离散度估计
      dds <- estimateDispersionsGeneEst(dds)
      dispersions(dds) <- mcols(dds)$dispGeneEst
      dds <- nbinomWaldTest(dds)
    })
    
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
      groups = paste(unique(groups), collapse = " vs "),
      group_sizes = paste(table(groups), collapse = ", "),
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

# 主程序
cat("=== 强大DESeq2分析 ===\n")

# 先分析GSE73338（已知有好的分组信息）
priority_datasets <- c("GSE73338")

cat("优先分析数据集:", paste(priority_datasets, collapse = ", "), "\n\n")

success_count <- 0
failed_datasets <- c()

for (geo_id in priority_datasets) {
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
