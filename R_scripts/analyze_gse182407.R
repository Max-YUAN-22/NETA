#!/usr/bin/env Rscript

# 下载和分析GSE182407数据集
# 作者: NETA团队
# 日期: 2024-01-15

# 加载必要的包
suppressPackageStartupMessages({
  library(GEOquery)
  library(Biobase)
  library(DESeq2)
  library(ggplot2)
  library(pheatmap)
  library(RColorBrewer)
  library(limma)
})

# 设置工作目录
setwd("/Users/Apple/Desktop/pcatools/NETA")

# 创建输出目录
if (!dir.exists("data/raw/GSE182407")) {
  dir.create("data/raw/GSE182407", recursive = TRUE)
}
if (!dir.exists("data/processed/analysis_results/deseq2/GSE182407")) {
  dir.create("data/processed/analysis_results/deseq2/GSE182407", recursive = TRUE)
}

# 下载GSE182407数据
download_gse182407 <- function() {
  cat("=== 下载GSE182407数据集 ===\n")
  
  tryCatch({
    # 下载GEO数据
    gse <- getGEO("GSE182407", destdir = "data/raw/GSE182407", GSEMatrix = TRUE)
    
    if (is.null(gse)) {
      cat("❌ 无法下载GSE182407数据\n")
      return(NULL)
    }
    
    cat("✅ GSE182407数据下载成功\n")
    
    # 获取表达矩阵
    if (is.list(gse)) {
      expr_data <- exprs(gse[[1]])
      pheno_data <- pData(gse[[1]])
    } else {
      expr_data <- exprs(gse)
      pheno_data <- pData(gse)
    }
    
    cat("表达矩阵维度:", dim(expr_data), "\n")
    cat("表型数据维度:", dim(pheno_data), "\n")
    
    # 保存原始数据
    write.csv(expr_data, "data/raw/GSE182407/GSE182407_expression_matrix.csv", row.names = TRUE)
    write.csv(pheno_data, "data/raw/GSE182407/GSE182407_phenotype_data.csv", row.names = TRUE)
    
    cat("✅ 原始数据已保存\n")
    
    # 分析表型数据
    cat("\n=== 表型数据分析 ===\n")
    cat("表型数据列名:\n")
    print(colnames(pheno_data))
    
    # 检查样本分组
    cat("\n样本分组信息:\n")
    if ("title" %in% colnames(pheno_data)) {
      cat("样本标题:\n")
      print(pheno_data$title)
    }
    
    if ("source_name_ch1" %in% colnames(pheno_data)) {
      cat("样本来源:\n")
      print(unique(pheno_data$source_name_ch1))
    }
    
    if ("characteristics_ch1" %in% colnames(pheno_data)) {
      cat("样本特征:\n")
      print(unique(pheno_data$characteristics_ch1))
    }
    
    return(list(expr_data = expr_data, pheno_data = pheno_data))
    
  }, error = function(e) {
    cat("❌ 下载失败:", e$message, "\n")
    return(NULL)
  })
}

# 分析GSE182407数据
analyze_gse182407 <- function(data_list) {
  if (is.null(data_list)) {
    cat("❌ 没有数据可分析\n")
    return(NULL)
  }
  
  cat("\n=== 分析GSE182407数据 ===\n")
  
  expr_data <- data_list$expr_data
  pheno_data <- data_list$pheno_data
  
  # 检查数据类型
  cat("表达数据前几行:\n")
  print(head(expr_data[, 1:5]))
  
  # 检查是否为整数计数
  is_integer <- all(expr_data == floor(expr_data))
  cat("是否为整数计数:", is_integer, "\n")
  
  # 检查数据范围
  cat("数据范围:", range(expr_data), "\n")
  cat("数据中位数:", median(expr_data), "\n")
  
  # 如果数据不是整数，尝试转换
  if (!is_integer) {
    cat("⚠️ 数据不是整数，可能是标准化数据\n")
    cat("尝试使用limma进行微阵列数据分析\n")
    
    # 使用limma分析
    return(analyze_with_limma(expr_data, pheno_data))
  } else {
    cat("✅ 数据是整数计数，使用DESeq2分析\n")
    return(analyze_with_deseq2(expr_data, pheno_data))
  }
}

# 使用limma分析
analyze_with_limma <- function(expr_data, pheno_data) {
  cat("\n=== 使用limma分析GSE182407 ===\n")
  
  tryCatch({
    # 创建分组
    # 基于样本名称或特征创建分组
    groups <- rep("Sample", ncol(expr_data))
    
    # 尝试从表型数据中提取分组信息
    if ("title" %in% colnames(pheno_data)) {
      titles <- pheno_data$title
      # 检查是否包含YAP1相关信息
      yap1_samples <- grepl("YAP1|knockdown|overexpression|KO|OE", titles, ignore.case = TRUE)
      groups[yap1_samples] <- "YAP1_intervention"
      groups[!yap1_samples] <- "Wild_type"
    }
    
    # 检查分组
    cat("分组情况:\n")
    print(table(groups))
    
    # 如果只有一组，无法进行差异分析
    if (length(unique(groups)) < 2) {
      cat("❌ 只有一组样本，无法进行差异分析\n")
      return(NULL)
    }
    
    # 创建设计矩阵
    design <- model.matrix(~0 + factor(groups))
    colnames(design) <- levels(factor(groups))
    
    # 拟合线性模型
    fit <- lmFit(expr_data, design)
    
    # 创建对比矩阵
    contrast_matrix <- makeContrasts(
      Wild_type_vs_YAP1 = Wild_type - YAP1_intervention,
      levels = design
    )
    
    # 对比拟合
    fit2 <- contrasts.fit(fit, contrast_matrix)
    fit2 <- eBayes(fit2)
    
    # 获取结果
    results <- topTable(fit2, adjust.method = "fdr", sort.by = "P", number = Inf)
    
    # 显著差异基因
    significant_genes <- subset(results, adj.P.Val < 0.05)
    
    cat("显著差异基因数:", nrow(significant_genes), "\n")
    cat("上调基因数:", sum(significant_genes$logFC > 0), "\n")
    cat("下调基因数:", sum(significant_genes$logFC < 0), "\n")
    
    # 保存结果
    output_dir <- "data/processed/analysis_results/deseq2/GSE182407"
    write.csv(results, file.path(output_dir, "limma_results.csv"), row.names = TRUE)
    write.csv(significant_genes, file.path(output_dir, "significant_genes.csv"), row.names = TRUE)
    
    # 生成图表
    generate_plots_limma(results, expr_data, pheno_data, output_dir)
    
    cat("✅ limma分析完成\n")
    return(list(
      significant_genes_count = nrow(significant_genes),
      upregulated_count = sum(significant_genes$logFC > 0),
      downregulated_count = sum(significant_genes$logFC < 0)
    ))
    
  }, error = function(e) {
    cat("❌ limma分析失败:", e$message, "\n")
    return(NULL)
  })
}

# 使用DESeq2分析
analyze_with_deseq2 <- function(expr_data, pheno_data) {
  cat("\n=== 使用DESeq2分析GSE182407 ===\n")
  
  tryCatch({
    # 创建分组
    groups <- rep("Sample", ncol(expr_data))
    
    if ("title" %in% colnames(pheno_data)) {
      titles <- pheno_data$title
      yap1_samples <- grepl("YAP1|knockdown|overexpression|KO|OE", titles, ignore.case = TRUE)
      groups[yap1_samples] <- "YAP1_intervention"
      groups[!yap1_samples] <- "Wild_type"
    }
    
    # 创建DESeq2对象
    colData <- data.frame(
      sample_id = colnames(expr_data),
      group = factor(groups)
    )
    
    dds <- DESeqDataSetFromMatrix(
      countData = expr_data,
      colData = colData,
      design = ~ group
    )
    
    # 过滤低表达基因
    dds <- dds[rowSums(counts(dds)) >= 10, ]
    
    # 运行DESeq2
    dds <- DESeq(dds)
    
    # 获取结果
    results <- results(dds, contrast = c("group", "Wild_type", "YAP1_intervention"))
    
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
    
    cat("✅ DESeq2分析完成\n")
    return(list(
      significant_genes_count = nrow(significant_genes),
      upregulated_count = sum(significant_genes$log2FoldChange > 0),
      downregulated_count = sum(significant_genes$log2FoldChange < 0)
    ))
    
  }, error = function(e) {
    cat("❌ DESeq2分析失败:", e$message, "\n")
    return(NULL)
  })
}

# 生成limma图表
generate_plots_limma <- function(results, expr_data, pheno_data, output_dir) {
  cat("生成limma图表...\n")
  
  # Volcano图
  png(file.path(output_dir, "volcano_plot.png"), width = 800, height = 600, res = 300)
  plot(results$logFC, -log10(results$P.Value), 
       pch = 20, col = ifelse(results$adj.P.Val < 0.05, "red", "gray"),
       xlab = "Log2 Fold Change", ylab = "-Log10 P-value",
       main = "GSE182407 Volcano Plot")
  abline(h = -log10(0.05), v = c(-1, 1), lty = 2)
  dev.off()
  
  # MA图
  png(file.path(output_dir, "ma_plot.png"), width = 800, height = 600, res = 300)
  plot(results$AveExpr, results$logFC, 
       pch = 20, col = ifelse(results$adj.P.Val < 0.05, "red", "gray"),
       xlab = "Average Expression", ylab = "Log2 Fold Change",
       main = "GSE182407 MA Plot")
  abline(h = 0, lty = 2)
  dev.off()
  
  cat("✅ 图表生成完成\n")
}

# 生成DESeq2图表
generate_plots_deseq2 <- function(results, dds, output_dir) {
  cat("生成DESeq2图表...\n")
  
  # Volcano图
  png(file.path(output_dir, "volcano_plot.png"), width = 800, height = 600, res = 300)
  plot(results$log2FoldChange, -log10(results$pvalue), 
       pch = 20, col = ifelse(results$padj < 0.05, "red", "gray"),
       xlab = "Log2 Fold Change", ylab = "-Log10 P-value",
       main = "GSE182407 Volcano Plot")
  abline(h = -log10(0.05), v = c(-1, 1), lty = 2)
  dev.off()
  
  # MA图
  png(file.path(output_dir, "ma_plot.png"), width = 800, height = 600, res = 300)
  plot(results$baseMean, results$log2FoldChange, 
       pch = 20, col = ifelse(results$padj < 0.05, "red", "gray"),
       xlab = "Base Mean", ylab = "Log2 Fold Change",
       main = "GSE182407 MA Plot")
  abline(h = 0, lty = 2)
  dev.off()
  
  cat("✅ 图表生成完成\n")
}

# 主函数
main <- function() {
  cat("=== GSE182407数据分析开始 ===\n")
  
  # 下载数据
  data_list <- download_gse182407()
  
  if (!is.null(data_list)) {
    # 分析数据
    result <- analyze_gse182407(data_list)
    
    if (!is.null(result)) {
      cat("\n=== 分析结果总结 ===\n")
      cat("显著差异基因数:", result$significant_genes_count, "\n")
      cat("上调基因数:", result$upregulated_count, "\n")
      cat("下调基因数:", result$downregulated_count, "\n")
      cat("✅ GSE182407分析完成！\n")
    }
  }
}

# 运行主函数
main()
