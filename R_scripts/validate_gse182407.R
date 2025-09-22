#!/usr/bin/env Rscript

# 验证GSE182407数据集
# 作者: NETA团队
# 日期: 2024-01-15

# 加载必要的包
suppressPackageStartupMessages({
  library(GEOquery)
  library(Biobase)
})

# 设置工作目录
setwd("/Users/Apple/Desktop/pcatools/NETA")

# 创建输出目录
if (!dir.exists("data/validation")) {
  dir.create("data/validation", recursive = TRUE)
}

# 验证GSE182407数据集
validate_gse182407 <- function() {
  cat("=== 验证GSE182407数据集 ===\n")
  
  tryCatch({
    # 获取GEO信息
    gse <- getGEO("GSE182407", destdir = "data/validation", GSEMatrix = FALSE)
    
    if (is.null(gse)) {
      cat("❌ GSE182407 无法获取GEO信息\n")
      return(FALSE)
    }
    
    # 检查实验类型
    experiment_type <- Meta(gse)$type
    cat("实验类型:", experiment_type, "\n")
    
    # 检查平台信息
    platforms <- Meta(gse)$platform
    cat("平台数量:", length(platforms), "\n")
    
    # 检查样本信息
    samples <- Meta(gse)$sample_id
    cat("样本数量:", length(samples), "\n")
    
    # 检查是否有RNA-seq相关关键词
    summary_text <- paste(Meta(gse)$summary, collapse = " ")
    design_text <- paste(Meta(gse)$overall_design, collapse = " ")
    all_text <- paste(summary_text, design_text, collapse = " ")
    
    cat("摘要信息:\n")
    cat(substr(summary_text, 1, 500), "...\n\n")
    
    cat("实验设计:\n")
    cat(substr(design_text, 1, 500), "...\n\n")
    
    # 检查关键词
    rnaseq_keywords <- c("RNA-seq", "RNAseq", "RNA sequencing", "high throughput sequencing", "Illumina", "NGS")
    microarray_keywords <- c("microarray", "array", "chip", "Affymetrix", "Agilent")
    
    has_rnaseq <- any(sapply(rnaseq_keywords, function(x) grepl(x, all_text, ignore.case = TRUE)))
    has_microarray <- any(sapply(microarray_keywords, function(x) grepl(x, all_text, ignore.case = TRUE)))
    
    cat("包含RNA-seq关键词:", has_rnaseq, "\n")
    cat("包含微阵列关键词:", has_microarray, "\n")
    
    # 检查生物学重复
    replicate_keywords <- c("biological replicate", "replicate", "n=3", "n=4", "n=5", "n=6", "n=7", "n=8", "n=9", "n=10")
    has_replicates <- any(sapply(replicate_keywords, function(x) grepl(x, all_text, ignore.case = TRUE)))
    cat("包含生物学重复信息:", has_replicates, "\n")
    
    # 检查野生型样本
    wildtype_keywords <- c("wild.type", "wild type", "control", "normal", "healthy", "non.tumor", "non tumor")
    has_wildtype <- any(sapply(wildtype_keywords, function(x) grepl(x, all_text, ignore.case = TRUE)))
    cat("包含野生型/对照信息:", has_wildtype, "\n")
    
    # 检查基因干预
    intervention_keywords <- c("CRISPR", "knockout", "knock.down", "transgenic", "mutant", "overexpression", "silencing")
    has_intervention <- any(sapply(intervention_keywords, function(x) grepl(x, all_text, ignore.case = TRUE)))
    cat("包含基因干预信息:", has_intervention, "\n")
    
    # 检查原始计数数据
    count_keywords <- c("raw count", "count matrix", "HTSeq", "featureCounts", "STAR", "integer count")
    has_counts <- any(sapply(count_keywords, function(x) grepl(x, all_text, ignore.case = TRUE)))
    cat("包含原始计数信息:", has_counts, "\n")
    
    # 检查神经内分泌肿瘤相关关键词
    net_keywords <- c("neuroendocrine", "pancreatic neuroendocrine", "lung neuroendocrine", "gastrointestinal neuroendocrine", "NET", "NEC")
    has_net <- any(sapply(net_keywords, function(x) grepl(x, all_text, ignore.case = TRUE)))
    cat("包含神经内分泌肿瘤关键词:", has_net, "\n")
    
    # 综合判断
    is_valid <- (has_rnaseq && !has_microarray && 
                 has_replicates && has_wildtype && 
                 !has_intervention && has_counts &&
                 has_net && length(samples) >= 6)
    
    cat("\n=== 验证结果 ===\n")
    cat("符合条件:", ifelse(is_valid, "✅ 是", "❌ 否"), "\n")
    
    if (is_valid) {
      cat("✅ GSE182407 是一个符合要求的神经内分泌肿瘤RNA-seq数据集！\n")
    } else {
      cat("❌ GSE182407 不符合要求，原因：\n")
      if (!has_rnaseq) cat("  - 不是RNA-seq数据\n")
      if (has_microarray) cat("  - 包含微阵列数据\n")
      if (!has_replicates) cat("  - 缺少生物学重复信息\n")
      if (!has_wildtype) cat("  - 缺少野生型/对照信息\n")
      if (has_intervention) cat("  - 包含基因干预\n")
      if (!has_counts) cat("  - 缺少原始计数信息\n")
      if (!has_net) cat("  - 不是神经内分泌肿瘤相关\n")
      if (length(samples) < 6) cat("  - 样本数量不足\n")
    }
    
    return(is_valid)
    
  }, error = function(e) {
    cat("❌ GSE182407 验证失败:", e$message, "\n")
    return(FALSE)
  })
}

# 执行验证
result <- validate_gse182407()

if (result) {
  cat("\n🎉 太好了！GSE182407符合要求，我们可以开始分析这个数据集！\n")
} else {
  cat("\n😞 GSE182407不符合要求，我们需要继续寻找其他数据集。\n")
}
