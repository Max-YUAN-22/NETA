#!/usr/bin/env Rscript

# 微阵列数据差异表达分析 - GSE73338
# 使用limma进行差异表达分析
# 作者: NETA团队
# 日期: 2024-01-15

# 加载必要的包
suppressPackageStartupMessages({
  library(limma)
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

# limma差异表达分析函数
run_limma_analysis <- function(geo_id) {
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
    if (length(common_samples) < 6) {
      cat("❌", geo_id, "样本数不足，跳过分析\n")
      return(FALSE)
    }
    
    expr_data <- expr_data[, common_samples]
    pheno_data <- pheno_data[common_samples, ]
    
    # 从title列提取分组信息
    titles <- as.character(pheno_data$title)
    cat("  - 样本标题:", paste(unique(titles), collapse = ", "), "\n")
    
    # 提取分组
    groups <- sapply(titles, function(x) {
      if (grepl("Non-functional", x, ignore.case = TRUE)) return("Non_functional")
      if (grepl("Insulinoma", x, ignore.case = TRUE)) return("Insulinoma")
      if (grepl("Normal pancreas", x, ignore.case = TRUE)) return("Normal")
      if (grepl("Normal pancreas islet", x, ignore.case = TRUE)) return("Normal")
      if (grepl("Functional", x, ignore.case = TRUE)) return("Functional")
      if (grepl("Metastases", x, ignore.case = TRUE)) return("Metastases")
      return("Other")
    })
    
    cat("  - 原始分组:", paste(unique(groups), collapse = ", "), "\n")
    cat("  - 原始样本数:", paste(table(groups), collapse = ", "), "\n")
    
    # 过滤掉样本数不足的分组
    group_counts <- table(groups)
    valid_groups <- names(group_counts)[group_counts >= 3]
    
    if (length(valid_groups) < 2) {
      cat("❌", geo_id, "有效分组不足，跳过分析\n")
      return(FALSE)
    }
    
    # 只保留有效分组的样本
    valid_samples <- names(groups)[groups %in% valid_groups]
    expr_data <- expr_data[, valid_samples]
    pheno_data <- pheno_data[valid_samples, ]
    groups <- groups[valid_samples]
    
    cat("  - 过滤后分组:", paste(unique(groups), collapse = ", "), "\n")
    cat("  - 过滤后样本数:", paste(table(groups), collapse = ", "), "\n")
    
    # 创建设计矩阵
    design <- model.matrix(~ 0 + factor(groups))
    colnames(design) <- levels(factor(groups))
    
    # 拟合线性模型
    fit <- lmFit(expr_data, design)
    
    # 创建对比矩阵
    contrasts <- makeContrasts(
      Non_functional_vs_Normal = Non_functional - Normal,
      Insulinoma_vs_Normal = Insulinoma - Normal,
      Functional_vs_Normal = Functional - Normal,
      Metastases_vs_Normal = Metastases - Normal,
      levels = design
    )
    
    # 拟合对比
    fit2 <- contrasts.fit(fit, contrasts)
    fit2 <- eBayes(fit2)
    
    # 获取结果
    res <- topTable(fit2, coef = 1, number = Inf, sort.by = "P")
    
    # 过滤显著基因
    sig_genes <- res[res$adj.P.Val < 0.05 & abs(res$logFC) > 1, ]
    cat("  - 显著差异基因:", nrow(sig_genes), "\n")
    
    # 创建输出目录
    output_dir <- paste0("data/processed/analysis_results/deseq2/", geo_id)
    if (!dir.exists(output_dir)) {
      dir.create(output_dir, recursive = TRUE)
    }
    
    # 1. 火山图
    volcano_data <- data.frame(
      gene = rownames(res),
      log2FC = res$logFC,
      pvalue = -log10(res$P.Value),
      padj = res$adj.P.Val,
      significant = res$adj.P.Val < 0.05 & abs(res$logFC) > 1
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
    plotMA(fit2, coef = 1, main = paste0("MA Plot - ", geo_id))
    dev.off()
    
    # 3. PCA图
    pca_result <- prcomp(t(expr_data), scale. = TRUE)
    pca_data <- data.frame(
      PC1 = pca_result$x[, 1],
      PC2 = pca_result$x[, 2],
      group = groups
    )
    
    png(paste0(output_dir, "/pca_plot.png"), width = 800, height = 600, res = 300)
    p <- ggplot(pca_data, aes(x = PC1, y = PC2, color = group)) +
      geom_point(size = 3, alpha = 0.8) +
      labs(
        title = paste0("PCA Plot - ", geo_id),
        x = paste0("PC1: ", round(summary(pca_result)$importance[2, 1] * 100), "% variance"),
        y = paste0("PC2: ", round(summary(pca_result)$importance[2, 2] * 100), "% variance")
      ) +
      sci_theme +
      theme(legend.position = "bottom")
    print(p)
    dev.off()
    
    # 4. 热图
    if (nrow(sig_genes) > 0) {
      # 选择top 50显著基因
      top_genes <- head(rownames(sig_genes), 50)
      heatmap_data <- expr_data[top_genes, ]
      
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
    write.csv(res, file = paste0(output_dir, "/limma_results.csv"))
    write.csv(sig_genes, file = paste0(output_dir, "/significant_genes.csv"))
    
    # 6. 生成统计报告
    stats <- list(
      dataset = geo_id,
      total_genes = nrow(expr_data),
      total_samples = ncol(expr_data),
      groups = paste(unique(groups), collapse = " vs "),
      group_sizes = paste(table(groups), collapse = ", "),
      significant_genes = nrow(sig_genes),
      upregulated = sum(sig_genes$logFC > 1, na.rm = TRUE),
      downregulated = sum(sig_genes$logFC < -1, na.rm = TRUE)
    )
    
    writeLines(
      paste0(names(stats), ": ", stats),
      paste0(output_dir, "/analysis_summary.txt")
    )
    
    cat("✅", geo_id, "分析完成\n")
    cat("  - 输出目录:", output_dir, "\n")
    cat("  - 显著基因:", nrow(sig_genes), "\n")
    cat("  - 上调基因:", sum(sig_genes$logFC > 1, na.rm = TRUE), "\n")
    cat("  - 下调基因:", sum(sig_genes$logFC < -1, na.rm = TRUE), "\n\n")
    
    return(TRUE)
    
  }, error = function(e) {
    cat("❌", geo_id, "分析失败:", e$message, "\n\n")
    return(FALSE)
  })
}

# 主程序
cat("=== 微阵列数据limma分析 ===\n")

# 分析GSE73338
geo_id <- "GSE73338"

if (run_limma_analysis(geo_id)) {
  cat("✅ GSE73338分析成功完成！\n")
} else {
  cat("❌ GSE73338分析失败\n")
}

cat("\n所有结果已保存到 data/processed/analysis_results/deseq2/ 目录\n")
cat("下一步: 更新前端链接\n")
