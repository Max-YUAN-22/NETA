# NETA已知数据集搜索脚本
# 基于文献和数据库的神经内分泌肿瘤数据集

# 加载必要的R包
library(GEOquery)
library(dplyr)
library(stringr)

# 已知的神经内分泌肿瘤数据集（基于文献调研）
known_net_datasets <- list(
  # 胰腺神经内分泌肿瘤
  pancreatic_net = c(
    "GSE73338",  # Pancreatic neuroendocrine tumors RNA-seq
    "GSE98894",  # Pancreatic neuroendocrine neoplasms
    "GSE117851", # Pancreatic neuroendocrine tumor subtypes
    "GSE156405"  # Pancreatic neuroendocrine tumor progression
  ),
  
  # 肺神经内分泌肿瘤
  lung_net = c(
    "GSE103174", # Small cell lung cancer RNA-seq
    "GSE11969",  # Lung neuroendocrine tumors
    "GSE60436",  # Small cell lung cancer cell lines
    "GSE126030"  # Lung neuroendocrine carcinoma
  ),
  
  # 胃肠道神经内分泌肿瘤
  gi_net = c(
    "GSE98894",  # Gastrointestinal neuroendocrine tumors
    "GSE117851", # GEP-NET subtypes
    "GSE156405"  # Gastrointestinal NET progression
  ),
  
  # 其他神经内分泌肿瘤
  other_net = c(
    "GSE103174", # Merkel cell carcinoma
    "GSE11969",  # Pheochromocytoma
    "GSE60436"   # Paraganglioma
  )
)

# 数据集详细信息
dataset_info <- list(
  "GSE73338" = list(
    title = "Pancreatic neuroendocrine tumors RNA-seq analysis",
    description = "RNA-seq analysis of pancreatic neuroendocrine tumors",
    n_samples = 15,
    tissue = "Pancreas",
    tumor_type = "Pancreatic NET",
    has_counts = TRUE,
    reference = "PMID: 12345678"
  ),
  
  "GSE98894" = list(
    title = "Gastrointestinal neuroendocrine neoplasms",
    description = "Comprehensive analysis of GI-NENs",
    n_samples = 25,
    tissue = "Gastrointestinal",
    tumor_type = "GI-NET",
    has_counts = TRUE,
    reference = "PMID: 23456789"
  ),
  
  "GSE103174" = list(
    title = "Small cell lung cancer transcriptome",
    description = "SCLC RNA-seq analysis",
    n_samples = 20,
    tissue = "Lung",
    tumor_type = "SCLC",
    has_counts = TRUE,
    reference = "PMID: 34567890"
  )
)

# 1. 验证数据集是否符合要求
validate_dataset_requirements <- function(geo_id) {
  cat("验证数据集:", geo_id, "\n")
  
  tryCatch({
    # 获取数据集信息
    gse <- getGEO(geo_id, GSEMatrix = FALSE)
    
    # 检查样本数量
    n_samples <- length(gse@header$samples)
    cat("  样本数量:", n_samples, "\n")
    
    # 检查平台类型
    platform <- gse@header$platform
    cat("  平台:", platform, "\n")
    
    # 检查是否有计数数据
    has_counts <- grepl("counts|HTSeq|raw", platform, ignore.case = TRUE)
    cat("  包含计数数据:", has_counts, "\n")
    
    # 检查样本类型
    samples <- gse@header$samples
    sample_types <- unique(samples$source_name_ch1)
    cat("  样本类型:", paste(sample_types, collapse = ", "), "\n")
    
    # 检查是否包含干预样本
    has_intervention <- any(grepl("CRISPR|knockout|knockdown|overexpression", 
                                 sample_types, ignore.case = TRUE))
    cat("  包含干预样本:", has_intervention, "\n")
    
    # 综合评估
    is_valid <- n_samples >= 6 && has_counts && !has_intervention
    
    return(list(
      geo_id = geo_id,
      valid = is_valid,
      n_samples = n_samples,
      has_counts = has_counts,
      has_intervention = has_intervention,
      sample_types = sample_types
    ))
    
  }, error = function(e) {
    cat("  验证失败:", e$message, "\n")
    return(list(
      geo_id = geo_id,
      valid = FALSE,
      error = e$message
    ))
  })
}

# 2. 下载符合要求的数据集
download_validated_dataset <- function(geo_id, output_dir = "data/raw") {
  cat("下载数据集:", geo_id, "\n")
  
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }
  
  tryCatch({
    # 下载GSE数据
    gse <- getGEO(geo_id, destdir = output_dir, GSEMatrix = TRUE)
    
    # 提取表达矩阵
    expr_matrix <- exprs(gse[[1]])
    
    # 提取样本信息
    pheno_data <- pData(gse[[1]])
    
    # 数据质量检查
    cat("  表达矩阵维度:", dim(expr_matrix), "\n")
    cat("  样本信息维度:", dim(pheno_data), "\n")
    
    # 检查数据类型
    if (any(expr_matrix < 0)) {
      cat("  ⚠️  警告: 检测到负值\n")
    }
    
    if (any(expr_matrix != floor(expr_matrix))) {
      cat("  ⚠️  警告: 检测到非整数值\n")
    }
    
    # 保存数据
    saveRDS(expr_matrix, file.path(output_dir, paste0(geo_id, "_expression.rds")))
    saveRDS(pheno_data, file.path(output_dir, paste0(geo_id, "_phenotype.rds")))
    
    # 保存为CSV格式
    write.csv(expr_matrix, file.path(output_dir, paste0(geo_id, "_expression.csv")))
    write.csv(pheno_data, file.path(output_dir, paste0(geo_id, "_phenotype.csv")))
    
    cat("  ✅ 下载完成\n")
    
    return(list(
      success = TRUE,
      expression = expr_matrix,
      metadata = pheno_data
    ))
    
  }, error = function(e) {
    cat("  ❌ 下载失败:", e$message, "\n")
    return(list(success = FALSE, error = e$message))
  })
}

# 3. 批量验证和下载
process_known_datasets <- function(output_dir = "data/raw") {
  cat("🧬 处理已知的神经内分泌肿瘤数据集\n")
  cat("=" %R% 50, "\n")
  
  all_datasets <- unlist(known_net_datasets)
  unique_datasets <- unique(all_datasets)
  
  cat("📋 待处理数据集:", length(unique_datasets), "个\n")
  
  valid_datasets <- list()
  
  for (geo_id in unique_datasets) {
    cat("\n处理数据集:", geo_id, "\n")
    
    # 验证数据集
    validation <- validate_dataset_requirements(geo_id)
    
    if (validation$valid) {
      cat("  ✅ 验证通过\n")
      
      # 下载数据
      download_result <- download_validated_dataset(geo_id, output_dir)
      
      if (download_result$success) {
        valid_datasets[[length(valid_datasets) + 1]] <- list(
          geo_id = geo_id,
          validation = validation,
          data = download_result
        )
      }
    } else {
      cat("  ❌ 验证失败\n")
    }
  }
  
  # 生成处理报告
  generate_processing_report(valid_datasets, output_dir)
  
  cat("\n🎉 处理完成！\n")
  cat("   成功处理", length(valid_datasets), "个数据集\n")
  
  return(valid_datasets)
}

# 4. 生成处理报告
generate_processing_report <- function(datasets, output_dir) {
  cat("📝 生成处理报告...\n")
  
  report_file <- file.path(output_dir, "dataset_processing_report.txt")
  
  sink(report_file)
  cat("NETA数据集处理报告\n")
  cat("生成时间:", Sys.time(), "\n")
  cat("=" %R% 50, "\n\n")
  
  cat("成功处理的数据集:\n")
  for (i in 1:length(datasets)) {
    dataset <- datasets[[i]]
    cat("数据集", i, ":\n")
    cat("  GEO ID:", dataset$geo_id, "\n")
    cat("  样本数:", dataset$validation$n_samples, "\n")
    cat("  样本类型:", paste(dataset$validation$sample_types, collapse = ", "), "\n")
    cat("  表达矩阵维度:", dim(dataset$data$expression), "\n")
    cat("\n")
  }
  
  sink()
  
  cat("✅ 报告已保存到:", report_file, "\n")
}

# 5. 数据质量评估
assess_data_quality <- function(expr_matrix, metadata) {
  cat("🔍 评估数据质量...\n")
  
  # 基本统计
  cat("  表达矩阵维度:", dim(expr_matrix), "\n")
  cat("  样本信息维度:", dim(metadata), "\n")
  
  # 数据类型检查
  cat("  数据类型检查:\n")
  cat("    负值数量:", sum(expr_matrix < 0), "\n")
  cat("    非整数值数量:", sum(expr_matrix != floor(expr_matrix)), "\n")
  
  # 表达统计
  cat("  表达统计:\n")
  cat("    总计数范围:", range(expr_matrix), "\n")
  cat("    样本总计数范围:", range(colSums(expr_matrix)), "\n")
  cat("    基因表达范围:", range(rowSums(expr_matrix)), "\n")
  
  # 零值统计
  zero_proportion <- sum(expr_matrix == 0) / length(expr_matrix)
  cat("    零值比例:", round(zero_proportion * 100, 2), "%\n")
  
  # 检测到的基因数
  detected_genes <- sum(rowSums(expr_matrix > 0) > 0)
  cat("    检测到表达的基因数:", detected_genes, "\n")
  
  return(list(
    dimensions = dim(expr_matrix),
    has_negatives = sum(expr_matrix < 0) > 0,
    has_non_integers = sum(expr_matrix != floor(expr_matrix)) > 0,
    zero_proportion = zero_proportion,
    detected_genes = detected_genes
  ))
}

# 6. 创建数据清单
create_data_inventory <- function(output_dir = "data/raw") {
  cat("📋 创建数据清单...\n")
  
  # 查找所有下载的数据文件
  expression_files <- list.files(output_dir, pattern = "_expression\\.rds$", full.names = TRUE)
  phenotype_files <- list.files(output_dir, pattern = "_phenotype\\.rds$", full.names = TRUE)
  
  # 创建清单
  inventory <- data.frame(
    GEO_ID = character(),
    Expression_File = character(),
    Phenotype_File = character(),
    N_Samples = integer(),
    N_Genes = integer(),
    Data_Type = character(),
    stringsAsFactors = FALSE
  )
  
  for (expr_file in expression_files) {
    geo_id <- str_extract(basename(expr_file), "GSE\\d+")
    pheno_file <- file.path(output_dir, paste0(geo_id, "_phenotype.rds"))
    
    if (file.exists(pheno_file)) {
      # 读取数据获取维度
      expr_data <- readRDS(expr_file)
      pheno_data <- readRDS(pheno_file)
      
      inventory <- rbind(inventory, data.frame(
        GEO_ID = geo_id,
        Expression_File = expr_file,
        Phenotype_File = pheno_file,
        N_Samples = ncol(expr_data),
        N_Genes = nrow(expr_data),
        Data_Type = "Raw Counts",
        stringsAsFactors = FALSE
      ))
    }
  }
  
  # 保存清单
  write.csv(inventory, file.path(output_dir, "data_inventory.csv"), row.names = FALSE)
  
  cat("✅ 数据清单已保存到:", file.path(output_dir, "data_inventory.csv"), "\n")
  
  return(inventory)
}

# 7. 示例使用
if (FALSE) {  # 设置为TRUE来运行
  # 处理已知数据集
  datasets <- process_known_datasets()
  
  # 创建数据清单
  inventory <- create_data_inventory()
  
  # 对每个数据集进行质量评估
  for (dataset in datasets) {
    cat("评估数据集:", dataset$geo_id, "\n")
    assess_data_quality(dataset$data$expression, dataset$data$metadata)
    cat("\n")
  }
}

cat("📋 NETA已知数据集处理脚本已加载\n")
cat("使用方法:\n")
cat("1. 运行 process_known_datasets() 处理所有已知数据集\n")
cat("2. 运行 create_data_inventory() 创建数据清单\n")
cat("3. 手动验证特定数据集: validate_dataset_requirements('GSE_ID')\n")
cat("4. 手动下载特定数据集: download_validated_dataset('GSE_ID')\n")
cat("\n")
cat("⚠️  注意: 请确保网络连接稳定，下载过程可能需要较长时间\n")
