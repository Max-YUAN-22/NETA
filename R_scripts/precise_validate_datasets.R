#!/usr/bin/env Rscript

# 精确验证已下载的神经内分泌癌数据集
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
if (!dir.exists("data/validation_results")) {
  dir.create("data/validation_results", recursive = TRUE)
}

# 精确验证单个数据集
precise_validate_dataset <- function(gse_id) {
  cat("=== 精确验证", gse_id, "===\n")
  
  tryCatch({
    # 检查本地文件
    soft_file <- file.path("data/search_results", paste0(gse_id, ".soft.gz"))
    
    if (!file.exists(soft_file)) {
      cat("❌ 本地文件不存在:", soft_file, "\n")
      return(NULL)
    }
    
    # 读取GEO数据
    gse <- getGEO(filename = soft_file, GSEMatrix = FALSE)
    
    if (is.null(gse)) {
      cat("❌ 无法读取GEO数据\n")
      return(NULL)
    }
    
    # 提取基本信息
    meta <- Meta(gse)
    
    # 基本信息
    title <- meta$title
    summary <- meta$summary
    type <- meta$type
    platform <- meta$platform
    sample_count <- length(meta$sample_id)
    
    cat("标题:", title, "\n")
    cat("样本数:", sample_count, "\n")
    cat("实验类型:", paste(type, collapse = ", "), "\n")
    
    # 检查是否为RNA-seq
    is_rnaseq <- any(grepl("Expression profiling by high throughput sequencing", type, ignore.case = TRUE))
    is_microarray <- any(grepl("Expression profiling by array", type, ignore.case = TRUE))
    
    cat("是RNA-seq:", is_rnaseq, "\n")
    cat("是微阵列:", is_microarray, "\n")
    
    # 检查神经内分泌癌关键词
    net_keywords <- c("neuroendocrine", "NET", "NEC", "carcinoid", "pheochromocytoma", "paraganglioma", "insulinoma", "gastrinoma")
    all_text <- paste(title, summary, collapse = " ")
    has_net_keywords <- any(sapply(net_keywords, function(x) grepl(x, all_text, ignore.case = TRUE)))
    
    cat("包含神经内分泌癌关键词:", has_net_keywords, "\n")
    
    # 检查样本数量
    has_sufficient_samples <- sample_count >= 6
    
    cat("样本数量充足:", has_sufficient_samples, "\n")
    
    # 检查是否有原始计数数据
    has_raw_counts <- any(grepl("raw count|HTSeq|featureCounts|count matrix|integer count", 
                               all_text, ignore.case = TRUE))
    
    cat("包含原始计数信息:", has_raw_counts, "\n")
    
    # 检查是否有生物学重复
    has_replicates <- any(grepl("biological replicate|replicate|n=3|n=4|n=5|n=6", 
                               all_text, ignore.case = TRUE))
    
    cat("包含生物学重复信息:", has_replicates, "\n")
    
    # 检查是否有野生型样本
    has_wildtype <- any(grepl("wild.type|wild type|control|normal|healthy", 
                             all_text, ignore.case = TRUE))
    
    cat("包含野生型/对照信息:", has_wildtype, "\n")
    
    # 检查是否有基因干预
    has_intervention <- any(grepl("knockout|CRISPR|shRNA|siRNA|overexpression|mutant", 
                                 all_text, ignore.case = TRUE))
    
    cat("包含基因干预:", has_intervention, "\n")
    
    # 综合评估
    is_valid <- is_rnaseq && !is_microarray && has_net_keywords && 
                has_sufficient_samples && has_raw_counts && 
                has_replicates && has_wildtype && !has_intervention
    
    cat("综合评估:", ifelse(is_valid, "✅ 符合条件", "❌ 不符合条件"), "\n")
    
    # 返回详细信息
    result <- list(
      geo_id = gse_id,
      title = title,
      summary = substr(summary, 1, 200),
      sample_count = sample_count,
      type = paste(type, collapse = ", "),
      is_rnaseq = is_rnaseq,
      is_microarray = is_microarray,
      has_net_keywords = has_net_keywords,
      has_sufficient_samples = has_sufficient_samples,
      has_raw_counts = has_raw_counts,
      has_replicates = has_replicates,
      has_wildtype = has_wildtype,
      has_intervention = has_intervention,
      is_valid = is_valid,
      pubmed_id = meta$pubmed_id,
      submission_date = meta$submission_date
    )
    
    return(result)
    
  }, error = function(e) {
    cat("❌ 验证失败:", e$message, "\n")
    return(NULL)
  })
}

# 验证所有已下载的数据集
validate_all_datasets <- function() {
  cat("=== 验证所有已下载的数据集 ===\n")
  
  # 获取所有.soft.gz文件
  soft_files <- list.files("data/search_results", pattern = "GSE.*\\.soft\\.gz$")
  gse_ids <- gsub("\\.soft\\.gz$", "", soft_files)
  
  cat("找到", length(gse_ids), "个数据集\n")
  
  valid_datasets <- list()
  invalid_datasets <- list()
  
  for (gse_id in gse_ids) {
    cat("\n", paste(rep("=", 60), collapse = ""), "\n")
    result <- precise_validate_dataset(gse_id)
    
    if (!is.null(result)) {
      if (result$is_valid) {
        valid_datasets[[gse_id]] <- result
        cat("✅", gse_id, "符合条件\n")
      } else {
        invalid_datasets[[gse_id]] <- result
        cat("❌", gse_id, "不符合条件\n")
      }
    }
  }
  
  # 保存结果
  save(valid_datasets, file = "data/validation_results/valid_datasets.RData")
  save(invalid_datasets, file = "data/validation_results/invalid_datasets.RData")
  
  # 生成总结报告
  cat("\n", paste(rep("=", 60), collapse = ""), "\n")
  cat("=== 验证结果总结 ===\n")
  cat("符合条件的数据集数量:", length(valid_datasets), "\n")
  cat("不符合条件的数据集数量:", length(invalid_datasets), "\n")
  
  if (length(valid_datasets) > 0) {
    cat("\n符合条件的数据集:\n")
    for (gse_id in names(valid_datasets)) {
      info <- valid_datasets[[gse_id]]
      cat("  ", gse_id, ":", info$title, "\n")
      cat("    样本数:", info$sample_count, "\n")
      cat("    类型:", info$type, "\n")
      cat("    发表年份:", substr(info$submission_date, 1, 4), "\n")
    }
  }
  
  if (length(invalid_datasets) > 0) {
    cat("\n不符合条件的数据集:\n")
    for (gse_id in names(invalid_datasets)) {
      info <- invalid_datasets[[gse_id]]
      cat("  ", gse_id, ":", info$title, "\n")
      cat("    原因: ")
      reasons <- c()
      if (!info$is_rnaseq) reasons <- c(reasons, "不是RNA-seq")
      if (info$is_microarray) reasons <- c(reasons, "是微阵列")
      if (!info$has_net_keywords) reasons <- c(reasons, "不包含神经内分泌癌关键词")
      if (!info$has_sufficient_samples) reasons <- c(reasons, "样本数不足")
      if (!info$has_raw_counts) reasons <- c(reasons, "缺少原始计数信息")
      if (!info$has_replicates) reasons <- c(reasons, "缺少生物学重复信息")
      if (!info$has_wildtype) reasons <- c(reasons, "缺少野生型/对照信息")
      if (info$has_intervention) reasons <- c(reasons, "包含基因干预")
      cat(paste(reasons, collapse = ", "), "\n")
    }
  }
  
  return(list(valid = valid_datasets, invalid = invalid_datasets))
}

# 主函数
main <- function() {
  cat("=== 精确验证神经内分泌癌数据集 ===\n")
  
  # 验证所有数据集
  results <- validate_all_datasets()
  
  cat("\n✅ 验证完成！结果已保存到 data/validation_results/\n")
  
  return(results)
}

# 运行主函数
main()
