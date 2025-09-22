#!/usr/bin/env Rscript

# NETA表型数据生成脚本
# 功能: 为每个数据集生成正确的表型数据用于DESeq2分析

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
})

# 设置工作目录
setwd("/Users/Apple/Desktop/pcatools/NETA")

# 为每个数据集生成表型数据
generate_phenotype_data <- function(dataset_id) {
  cat("生成表型数据:", dataset_id, "\n")
  
  # 读取原始表型数据
  pheno_file <- paste0("data/raw/", dataset_id, "/phenotype_data.csv")
  
  if (!file.exists(pheno_file)) {
    cat("警告: 表型数据文件不存在", dataset_id, "\n")
    return(NULL)
  }
  
  # 读取原始数据
  pheno_data <- read_csv(pheno_file, show_col_types = FALSE)
  
  # 根据数据集生成分组信息
  if (dataset_id == "GSE73338") {
    # 胰腺神经内分泌肿瘤：Non-functional PanNET vs Insulinoma
    pheno_data$group <- ifelse(grepl("Non-functional", pheno_data$title), "Non_functional", "Insulinoma")
  } else if (dataset_id == "GSE98894") {
    # 胃肠道神经内分泌肿瘤：根据title分组
    pheno_data$group <- ifelse(grepl("NET", pheno_data$title), "NET", "Control")
  } else if (dataset_id == "GSE103174") {
    # 小细胞肺癌：根据title分组
    pheno_data$group <- ifelse(grepl("SCLC", pheno_data$title), "SCLC", "Control")
  } else if (dataset_id == "GSE117851") {
    # 胰腺NET分子亚型
    pheno_data$group <- ifelse(grepl("Type", pheno_data$title), "Type1", "Type2")
  } else if (dataset_id == "GSE156405") {
    # 胰腺NET进展
    pheno_data$group <- ifelse(grepl("Primary", pheno_data$title), "Primary", "Metastatic")
  } else if (dataset_id == "GSE11969") {
    # 肺神经内分泌肿瘤
    pheno_data$group <- ifelse(grepl("NET", pheno_data$title), "NET", "Control")
  } else if (dataset_id == "GSE60436") {
    # SCLC细胞系
    pheno_data$group <- ifelse(grepl("SCLC", pheno_data$title), "SCLC", "Control")
  } else if (dataset_id == "GSE126030") {
    # 肺神经内分泌癌亚型
    pheno_data$group <- ifelse(grepl("Type", pheno_data$title), "Type1", "Type2")
  } else {
    # 默认分组
    pheno_data$group <- ifelse(grepl("Control", pheno_data$title), "Control", "Treatment")
  }
  
  # 创建sample_id列
  pheno_data$sample_id <- pheno_data$geo_accession
  
  # 选择需要的列
  new_pheno_data <- pheno_data %>%
    select(sample_id, group, title, geo_accession)
  
  # 保存新的表型数据
  output_file <- paste0("data/raw/", dataset_id, "/phenotype_data_processed.csv")
  write_csv(new_pheno_data, output_file)
  
  cat("表型数据已保存:", output_file, "\n")
  cat("样本数:", nrow(new_pheno_data), "\n")
  cat("分组:", paste(unique(new_pheno_data$group), collapse = ", "), "\n")
  
  return(new_pheno_data)
}

# 批量生成所有数据集的表型数据
batch_generate_phenotype <- function() {
  datasets <- c("GSE73338", "GSE98894", "GSE103174", "GSE117851", 
                "GSE156405", "GSE11969", "GSE60436", "GSE126030")
  
  for (dataset in datasets) {
    cat("\n=== 处理数据集:", dataset, "===\n")
    generate_phenotype_data(dataset)
  }
}

# 主函数
main <- function() {
  cat("=== NETA表型数据生成 ===\n")
  
  # 批量生成表型数据
  batch_generate_phenotype()
  
  cat("\n表型数据生成完成！\n")
}

# 如果直接运行脚本
if (!interactive()) {
  main()
}
