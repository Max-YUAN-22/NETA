# R script to generate detailed validation report

# Load validation results
load("data/validation_results/invalid_datasets.RData")
load("data/validation_results/valid_datasets.RData")

cat("=== 神经内分泌肿瘤数据集验证报告 ===\n")
cat("验证时间:", Sys.time(), "\n\n")

cat("符合条件的数据集数量:", length(valid_datasets), "\n")
cat("不符合条件的数据集数量:", length(invalid_datasets), "\n\n")

if (length(valid_datasets) > 0) {
  cat("✅ 符合条件的数据集:\n")
  for (id in names(valid_datasets)) {
    cat("  -", id, "\n")
  }
  cat("\n")
}

if (length(invalid_datasets) > 0) {
  cat("❌ 不符合条件的数据集详细分析:\n")
  
  # 统计各种不符合条件的原因
  reasons <- sapply(invalid_datasets, function(x) x$reason)
  reason_counts <- table(reasons)
  
  cat("\n不符合条件的原因统计:\n")
  for (reason in names(reason_counts)) {
    cat("  -", reason, ":", reason_counts[reason], "个数据集\n")
  }
  
  cat("\n各数据集不符合条件的原因:\n")
  for (id in names(invalid_datasets)) {
    cat("  -", id, ":", invalid_datasets[[id]]$reason, "\n")
  }
}

cat("\n=== 建议 ===\n")
if (length(valid_datasets) == 0) {
  cat("❌ 没有找到符合严格条件的数据集。建议：\n")
  cat("1. 放宽验证条件（如允许微阵列数据，但不分析）\n")
  cat("2. 扩大搜索范围，使用更多关键词\n")
  cat("3. 考虑包含基因干预的数据集，但分析时过滤掉干预样本\n")
  cat("4. 降低生物学重复要求（如每组≥2个样本）\n")
} else {
  cat("✅ 找到", length(valid_datasets), "个符合条件的数据集，可以开始分析。\n")
}
