#!/usr/bin/env Rscript

# 下载所有15个NETA数据集的真实GEO数据
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

# 创建数据目录
if (!dir.exists("data/raw")) {
  dir.create("data/raw", recursive = TRUE)
}

# 所有15个数据集列表
datasets <- c(
  "GSE73338", "GSE98894", "GSE103174", "GSE117851", "GSE156405",
  "GSE11969", "GSE60436", "GSE126030", "GSE165552", "GSE10245",
  "GSE19830", "GSE30554", "GSE59739", "GSE60361", "GSE71585"
)

cat("=== 开始下载所有15个NETA数据集 ===\n")
cat("数据集列表:", paste(datasets, collapse = ", "), "\n")
cat("总数据集数:", length(datasets), "\n\n")

# 下载函数
download_dataset <- function(geo_id) {
  cat("正在下载数据集:", geo_id, "\n")
  
  tryCatch({
    # 下载GEO数据
    gse <- getGEO(geo_id, destdir = "data/raw", GSEMatrix = TRUE)
    
    if (is.list(gse)) {
      gse <- gse[[1]]
    }
    
    # 保存表达矩阵
    expr_data <- exprs(gse)
    write.csv(expr_data, file = paste0("data/raw/", geo_id, "_expression_matrix.csv"), row.names = TRUE)
    
    # 保存表型数据
    pheno_data <- pData(gse)
    write.csv(pheno_data, file = paste0("data/raw/", geo_id, "_phenotype_data.csv"), row.names = TRUE)
    
    # 保存特征数据
    feature_data <- fData(gse)
    write.csv(feature_data, file = paste0("data/raw/", geo_id, "_feature_data.csv"), row.names = TRUE)
    
    cat("✅", geo_id, "下载成功\n")
    cat("  - 表达矩阵:", nrow(expr_data), "基因 x", ncol(expr_data), "样本\n")
    cat("  - 表型数据:", nrow(pheno_data), "样本\n")
    cat("  - 特征数据:", nrow(feature_data), "特征\n\n")
    
    return(TRUE)
    
  }, error = function(e) {
    cat("❌", geo_id, "下载失败:", e$message, "\n\n")
    return(FALSE)
  })
}

# 批量下载所有数据集
success_count <- 0
failed_datasets <- c()

for (geo_id in datasets) {
  if (download_dataset(geo_id)) {
    success_count <- success_count + 1
  } else {
    failed_datasets <- c(failed_datasets, geo_id)
  }
  
  # 避免请求过于频繁
  Sys.sleep(2)
}

# 总结
cat("=== 下载完成 ===\n")
cat("成功下载:", success_count, "个数据集\n")
cat("失败数据集:", length(failed_datasets), "个\n")

if (length(failed_datasets) > 0) {
  cat("失败的数据集:", paste(failed_datasets, collapse = ", "), "\n")
}

cat("\n所有数据已保存到 data/raw/ 目录\n")
cat("下一步: 运行表型数据处理脚本\n")
