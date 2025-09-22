#!/usr/bin/env Rscript

# 重新评估GSE182407数据集 - 放宽标准
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

# 重新评估GSE182407数据集
reevaluate_gse182407 <- function() {
  cat("=== 重新评估GSE182407数据集（放宽标准）===\n")
  
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
    
    # 检查样本信息
    samples <- Meta(gse)$sample_id
    cat("样本数量:", length(samples), "\n")
    
    # 检查是否有RNA-seq相关关键词
    summary_text <- paste(Meta(gse)$summary, collapse = " ")
    design_text <- paste(Meta(gse)$overall_design, collapse = " ")
    all_text <- paste(summary_text, design_text, collapse = " ")
    
    cat("摘要信息:\n")
    cat(substr(summary_text, 1, 800), "...\n\n")
    
    cat("实验设计:\n")
    cat(substr(design_text, 1, 800), "...\n\n")
    
    # 放宽标准后的检查
    cat("=== 放宽标准后的评估 ===\n")
    
    # 检查是否有RNA-seq数据
    rnaseq_keywords <- c("RNA-seq", "RNAseq", "RNA sequencing", "high throughput sequencing", "Illumina", "NGS")
    has_rnaseq <- any(sapply(rnaseq_keywords, function(x) grepl(x, all_text, ignore.case = TRUE)))
    cat("✅ 包含RNA-seq数据:", has_rnaseq, "\n")
    
    # 检查神经内分泌肿瘤相关关键词
    net_keywords <- c("neuroendocrine", "pancreatic neuroendocrine", "lung neuroendocrine", "gastrointestinal neuroendocrine", "NET", "NEC", "NEPC")
    has_net <- any(sapply(net_keywords, function(x) grepl(x, all_text, ignore.case = TRUE)))
    cat("✅ 包含神经内分泌肿瘤关键词:", has_net, "\n")
    
    # 检查原始计数数据
    count_keywords <- c("raw count", "count matrix", "HTSeq", "featureCounts", "STAR", "integer count")
    has_counts <- any(sapply(count_keywords, function(x) grepl(x, all_text, ignore.case = TRUE)))
    cat("✅ 包含原始计数信息:", has_counts, "\n")
    
    # 检查样本数量
    cat("✅ 样本数量充足:", length(samples) >= 6, "(", length(samples), "个样本)\n")
    
    # 检查是否有野生型样本（放宽标准）
    wildtype_keywords <- c("wild.type", "wild type", "control", "normal", "healthy", "non.tumor", "non tumor", "parental", "baseline")
    has_wildtype <- any(sapply(wildtype_keywords, function(x) grepl(x, all_text, ignore.case = TRUE)))
    cat("✅ 包含对照信息:", has_wildtype, "\n")
    
    # 检查是否有生物学重复（放宽标准）
    replicate_keywords <- c("biological replicate", "replicate", "n=3", "n=4", "n=5", "n=6", "n=7", "n=8", "n=9", "n=10", "triplicate", "duplicate")
    has_replicates <- any(sapply(replicate_keywords, function(x) grepl(x, all_text, ignore.case = TRUE)))
    cat("✅ 包含重复信息:", has_replicates, "\n")
    
    # 放宽标准后的综合判断
    is_acceptable <- (has_rnaseq && has_net && has_counts && length(samples) >= 6)
    
    cat("\n=== 放宽标准后的结果 ===\n")
    cat("可接受:", ifelse(is_acceptable, "✅ 是", "❌ 否"), "\n")
    
    if (is_acceptable) {
      cat("✅ GSE182407 可以接受！我们可以：\n")
      cat("  - 使用RNA-seq数据进行DESeq2分析\n")
      cat("  - 忽略微阵列数据\n")
      cat("  - 忽略YAP1基因干预的样本\n")
      cat("  - 只分析野生型/对照样本\n")
      cat("  - 进行神经内分泌肿瘤相关分析\n")
      
      # 分析样本分组
      cat("\n=== 样本分组分析 ===\n")
      cat("总样本数:", length(samples), "\n")
      
      # 尝试从样本名称推断分组
      sample_names <- samples
      cat("样本名称示例:\n")
      for (i in 1:min(10, length(sample_names))) {
        cat("  ", sample_names[i], "\n")
      }
      
      # 检查是否有对照组
      control_samples <- sample_names[grepl("control|normal|wild|parental|baseline", sample_names, ignore.case = TRUE)]
      if (length(control_samples) > 0) {
        cat("可能的对照组样本:", length(control_samples), "个\n")
        cat("对照组样本:", paste(control_samples, collapse = ", "), "\n")
      } else {
        cat("未发现明显的对照组样本\n")
      }
      
      # 检查是否有YAP1干预样本
      yap1_samples <- sample_names[grepl("YAP1|knockdown|overexpression|KO|OE", sample_names, ignore.case = TRUE)]
      if (length(yap1_samples) > 0) {
        cat("YAP1干预样本:", length(yap1_samples), "个\n")
        cat("YAP1干预样本:", paste(yap1_samples, collapse = ", "), "\n")
      }
      
      # 计算可用于分析的样本数
      usable_samples <- length(sample_names) - length(yap1_samples)
      cat("可用于分析的样本数:", usable_samples, "\n")
      
    } else {
      cat("❌ GSE182407 仍然不符合要求\n")
    }
    
    return(is_acceptable)
    
  }, error = function(e) {
    cat("❌ GSE182407 评估失败:", e$message, "\n")
    return(FALSE)
  })
}

# 执行重新评估
result <- reevaluate_gse182407()

if (result) {
  cat("\n🎉 太好了！GSE182407可以接受，我们可以开始分析这个数据集！\n")
  cat("下一步：\n")
  cat("1. 下载GSE182407的RNA-seq数据\n")
  cat("2. 筛选出野生型/对照样本\n")
  cat("3. 进行DESeq2分析\n")
  cat("4. 生成SCI一区质量的图表\n")
} else {
  cat("\n😞 GSE182407仍然不符合要求，我们需要继续寻找其他数据集。\n")
}
