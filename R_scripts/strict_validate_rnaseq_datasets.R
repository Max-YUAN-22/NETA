#!/usr/bin/env Rscript

# 精确搜索真正的神经内分泌肿瘤Bulk RNA-seq数据集
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

# 更精确的搜索策略 - 基于已知的神经内分泌肿瘤RNA-seq研究
precise_search_datasets <- c(
  # 胰腺神经内分泌肿瘤 - 已知有RNA-seq研究
  "GSE73338",  # 胰腺NET - 但之前验证是微阵列
  "GSE117851", # 胰腺NET - 但之前验证是微阵列
  
  # 肺神经内分泌肿瘤
  "GSE103174", # 肺NET - 但之前验证是微阵列
  
  # 新的搜索策略 - 基于PubMed文献
  "GSE114012", # 胰腺NET RNA-seq
  "GSE124341", # 神经内分泌肿瘤
  "GSE132608", # 胰腺NET
  "GSE140686", # 神经内分泌肿瘤
  "GSE145837", # 胰腺NET
  "GSE150316", # 神经内分泌肿瘤
  "GSE160756", # 胰腺NET
  "GSE164760", # 神经内分泌肿瘤
  "GSE171110", # 胰腺NET
  "GSE180473", # 神经内分泌肿瘤
  
  # 基于TCGA数据的神经内分泌肿瘤
  "GSE156405", # TCGA胰腺NET
  "GSE165552", # TCGA胰腺NET
  
  # 其他可能的RNA-seq数据集
  "GSE59739",  # 胰腺NET
  "GSE60361",  # 神经内分泌肿瘤
  "GSE71585",  # 胰腺NET
  "GSE98894",  # 神经内分泌肿瘤
  "GSE126030", # 胰腺NET
  "GSE30554",  # 神经内分泌肿瘤
  
  # 新增搜索 - 基于更广泛的神经内分泌肿瘤研究
  "GSE114012", # 重复
  "GSE124341", # 重复
  "GSE132608", # 重复
  "GSE140686", # 重复
  "GSE145837", # 重复
  "GSE150316", # 重复
  "GSE160756", # 重复
  "GSE164760", # 重复
  "GSE171110", # 重复
  "GSE180473"  # 重复
)

# 去重
precise_search_datasets <- unique(precise_search_datasets)

# 更严格的验证函数
strict_validate_dataset <- function(geo_id) {
  cat("严格验证数据集:", geo_id, "\n")
  
  tryCatch({
    # 获取GEO信息
    gse <- getGEO(geo_id, destdir = "data/validation", GSEMatrix = FALSE)
    
    if (is.null(gse)) {
      cat("❌", geo_id, "无法获取GEO信息\n")
      return(FALSE)
    }
    
    # 检查实验类型 - 必须是RNA-seq
    experiment_type <- Meta(gse)$type
    cat("  - 实验类型:", experiment_type, "\n")
    
    if (!grepl("high throughput sequencing", experiment_type, ignore.case = TRUE)) {
      cat("❌", geo_id, "不是高通量测序实验\n")
      return(FALSE)
    }
    
    # 检查样本信息
    samples <- Meta(gse)$sample_id
    cat("  - 样本数量:", length(samples), "\n")
    
    if (length(samples) < 6) {  # 至少需要6个样本才能有2组，每组3个重复
      cat("❌", geo_id, "样本数量不足\n")
      return(FALSE)
    }
    
    # 检查是否有RNA-seq相关关键词
    summary_text <- paste(Meta(gse)$summary, collapse = " ")
    design_text <- paste(Meta(gse)$overall_design, collapse = " ")
    all_text <- paste(summary_text, design_text, collapse = " ")
    
    # 检查关键词
    rnaseq_keywords <- c("RNA-seq", "RNAseq", "RNA sequencing", "high throughput sequencing", "Illumina", "NGS")
    microarray_keywords <- c("microarray", "array", "chip", "Affymetrix", "Agilent")
    
    has_rnaseq <- any(sapply(rnaseq_keywords, function(x) grepl(x, all_text, ignore.case = TRUE)))
    has_microarray <- any(sapply(microarray_keywords, function(x) grepl(x, all_text, ignore.case = TRUE)))
    
    cat("  - 包含RNA-seq关键词:", has_rnaseq, "\n")
    cat("  - 包含微阵列关键词:", has_microarray, "\n")
    
    if (!has_rnaseq || has_microarray) {
      cat("❌", geo_id, "不是纯RNA-seq数据\n")
      return(FALSE)
    }
    
    # 检查生物学重复 - 更严格的检查
    replicate_keywords <- c("biological replicate", "replicate", "n=3", "n=4", "n=5", "n=6", "n=7", "n=8", "n=9", "n=10")
    has_replicates <- any(sapply(replicate_keywords, function(x) grepl(x, all_text, ignore.case = TRUE)))
    cat("  - 包含生物学重复信息:", has_replicates, "\n")
    
    # 检查野生型样本
    wildtype_keywords <- c("wild.type", "wild type", "control", "normal", "healthy", "non.tumor", "non tumor")
    has_wildtype <- any(sapply(wildtype_keywords, function(x) grepl(x, all_text, ignore.case = TRUE)))
    cat("  - 包含野生型/对照信息:", has_wildtype, "\n")
    
    # 检查基因干预
    intervention_keywords <- c("CRISPR", "knockout", "knock.down", "transgenic", "mutant", "overexpression", "silencing")
    has_intervention <- any(sapply(intervention_keywords, function(x) grepl(x, all_text, ignore.case = TRUE)))
    cat("  - 包含基因干预信息:", has_intervention, "\n")
    
    if (has_intervention) {
      cat("❌", geo_id, "包含基因干预\n")
      return(FALSE)
    }
    
    # 检查原始计数数据
    count_keywords <- c("raw count", "count matrix", "HTSeq", "featureCounts", "STAR", "integer count")
    has_counts <- any(sapply(count_keywords, function(x) grepl(x, all_text, ignore.case = TRUE)))
    cat("  - 包含原始计数信息:", has_counts, "\n")
    
    # 综合判断 - 更严格的标准
    is_valid <- (has_rnaseq && !has_microarray && 
                 has_replicates && has_wildtype && 
                 !has_intervention && has_counts &&
                 length(samples) >= 6)
    
    cat("  - 验证结果:", ifelse(is_valid, "✅ 符合条件", "❌ 不符合条件"), "\n")
    
    return(is_valid)
    
  }, error = function(e) {
    cat("❌", geo_id, "验证失败:", e$message, "\n")
    return(FALSE)
  })
}

# 批量严格验证数据集
cat("=== 开始严格验证神经内分泌肿瘤RNA-seq数据集 ===\n")
cat("候选数据集:", paste(precise_search_datasets, collapse = ", "), "\n")
cat("总数据集数:", length(precise_search_datasets), "\n\n")

valid_datasets <- c()
invalid_datasets <- c()

for (geo_id in precise_search_datasets) {
  if (strict_validate_dataset(geo_id)) {
    valid_datasets <- c(valid_datasets, geo_id)
  } else {
    invalid_datasets <- c(invalid_datasets, geo_id)
  }
  cat("\n")
  
  # 避免请求过于频繁
  Sys.sleep(2)
}

# 总结结果
cat("=== 严格验证完成 ===\n")
cat("符合条件的数据集:", length(valid_datasets), "个\n")
if (length(valid_datasets) > 0) {
  cat("有效数据集:", paste(valid_datasets, collapse = ", "), "\n")
}

cat("不符合条件的数据集:", length(invalid_datasets), "个\n")
if (length(invalid_datasets) > 0) {
  cat("无效数据集:", paste(invalid_datasets, collapse = ", "), "\n")
}

# 保存结果
if (length(valid_datasets) > 0) {
  writeLines(valid_datasets, "data/validation/valid_datasets.txt")
}
if (length(invalid_datasets) > 0) {
  writeLines(invalid_datasets, "data/validation/invalid_datasets.txt")
}

cat("\n结果已保存到 data/validation/ 目录\n")

if (length(valid_datasets) >= 15) {
  cat("✅ 找到足够的数据集进行DESeq2分析\n")
} else {
  cat("❌ 需要继续搜索更多数据集\n")
  cat("建议:\n")
  cat("1. 扩大搜索范围到其他癌症类型\n")
  cat("2. 联系相关研究人员获取未公开数据\n")
  cat("3. 考虑使用TCGA等大型数据库\n")
}
