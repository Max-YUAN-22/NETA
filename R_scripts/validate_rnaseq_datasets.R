#!/usr/bin/env Rscript

# 搜索和验证真正的神经内分泌肿瘤RNA-seq数据集
# 作者: NETA团队
# 日期: 2024-01-15

# 加载必要的包
suppressPackageStartupMessages({
  library(GEOquery)
  library(Biobase)
  library(limma)
})

# 设置工作目录
setwd("/Users/Apple/Desktop/pcatools/NETA")

# 创建输出目录
if (!dir.exists("data/validation")) {
  dir.create("data/validation", recursive = TRUE)
}

# 已知的神经内分泌肿瘤相关数据集列表（需要验证）
candidate_datasets <- c(
  # 胰腺神经内分泌肿瘤
  "GSE73338", "GSE117851", "GSE156405", "GSE165552", "GSE59739",
  
  # 肺神经内分泌肿瘤
  "GSE103174", "GSE11969", "GSE60436", "GSE126030", "GSE10245",
  
  # 胃肠道神经内分泌肿瘤
  "GSE98894", "GSE19830",
  
  # 其他神经内分泌肿瘤
  "GSE30554", "GSE60361", "GSE71585",
  
  # 新增候选数据集
  "GSE114012", "GSE124341", "GSE132608", "GSE140686", "GSE145837",
  "GSE150316", "GSE160756", "GSE164760", "GSE171110", "GSE180473"
)

# 验证数据集函数
validate_dataset <- function(geo_id) {
  cat("验证数据集:", geo_id, "\n")
  
  tryCatch({
    # 获取GEO信息
    gse <- getGEO(geo_id, destdir = "data/validation", GSEMatrix = FALSE)
    
    if (is.null(gse)) {
      cat("❌", geo_id, "无法获取GEO信息\n")
      return(FALSE)
    }
    
    # 检查实验类型
    experiment_type <- Meta(gse)$type
    cat("  - 实验类型:", experiment_type, "\n")
    
    # 检查平台信息
    platforms <- Meta(gse)$platform
    cat("  - 平台数量:", length(platforms), "\n")
    
    # 检查样本信息
    samples <- Meta(gse)$sample_id
    cat("  - 样本数量:", length(samples), "\n")
    
    # 检查是否有RNA-seq相关关键词
    summary_text <- paste(Meta(gse)$summary, collapse = " ")
    design_text <- paste(Meta(gse)$overall_design, collapse = " ")
    all_text <- paste(summary_text, design_text, collapse = " ")
    
    # 检查关键词
    rnaseq_keywords <- c("RNA-seq", "RNAseq", "RNA sequencing", "high throughput sequencing")
    microarray_keywords <- c("microarray", "array", "chip", "Affymetrix", "Illumina")
    
    has_rnaseq <- any(sapply(rnaseq_keywords, function(x) grepl(x, all_text, ignore.case = TRUE)))
    has_microarray <- any(sapply(microarray_keywords, function(x) grepl(x, all_text, ignore.case = TRUE)))
    
    cat("  - 包含RNA-seq关键词:", has_rnaseq, "\n")
    cat("  - 包含微阵列关键词:", has_microarray, "\n")
    
    # 检查生物学重复
    has_replicates <- grepl("biological replicate|replicate", all_text, ignore.case = TRUE)
    cat("  - 包含生物学重复信息:", has_replicates, "\n")
    
    # 检查野生型样本
    has_wildtype <- grepl("wild.type|wild type|control|normal", all_text, ignore.case = TRUE)
    cat("  - 包含野生型/对照信息:", has_wildtype, "\n")
    
    # 检查基因干预
    has_intervention <- grepl("CRISPR|knockout|knock.down|transgenic|mutant", all_text, ignore.case = TRUE)
    cat("  - 包含基因干预信息:", has_intervention, "\n")
    
    # 综合判断
    is_valid <- has_rnaseq && !has_microarray && has_replicates && has_wildtype && !has_intervention
    
    cat("  - 验证结果:", ifelse(is_valid, "✅ 符合条件", "❌ 不符合条件"), "\n")
    
    return(is_valid)
    
  }, error = function(e) {
    cat("❌", geo_id, "验证失败:", e$message, "\n")
    return(FALSE)
  })
}

# 批量验证数据集
cat("=== 开始验证神经内分泌肿瘤RNA-seq数据集 ===\n")
cat("候选数据集:", paste(candidate_datasets, collapse = ", "), "\n")
cat("总数据集数:", length(candidate_datasets), "\n\n")

valid_datasets <- c()
invalid_datasets <- c()

for (geo_id in candidate_datasets) {
  if (validate_dataset(geo_id)) {
    valid_datasets <- c(valid_datasets, geo_id)
  } else {
    invalid_datasets <- c(invalid_datasets, geo_id)
  }
  cat("\n")
  
  # 避免请求过于频繁
  Sys.sleep(2)
}

# 总结结果
cat("=== 验证完成 ===\n")
cat("符合条件的数据集:", length(valid_datasets), "个\n")
if (length(valid_datasets) > 0) {
  cat("有效数据集:", paste(valid_datasets, collapse = ", "), "\n")
}

cat("不符合条件的数据集:", length(invalid_datasets), "个\n")
if (length(invalid_datasets) > 0) {
  cat("无效数据集:", paste(invalid_datasets, collapse = ", "), "\n")
}

# 保存结果
writeLines(valid_datasets, "data/validation/valid_datasets.txt")
writeLines(invalid_datasets, "data/validation/invalid_datasets.txt")

cat("\n结果已保存到 data/validation/ 目录\n")

if (length(valid_datasets) >= 15) {
  cat("✅ 找到足够的数据集进行DESeq2分析\n")
} else {
  cat("❌ 需要继续搜索更多数据集\n")
}
