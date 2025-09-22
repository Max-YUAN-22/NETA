# NETA数据收集脚本
# 搜索和下载神经内分泌肿瘤Bulk-RNA-seq数据

# 加载必要的R包
library(GEOquery)
library(SRAdb)
library(rentrez)
library(dplyr)
library(stringr)
library(readr)
library(httr)
library(jsonlite)

# 设置搜索参数
search_keywords <- c(
  "neuroendocrine tumor RNA-seq",
  "neuroendocrine carcinoma RNA-seq", 
  "pancreatic neuroendocrine tumor RNA-seq",
  "lung neuroendocrine tumor RNA-seq",
  "small cell lung cancer RNA-seq",
  "carcinoid tumor RNA-seq",
  "NET RNA-seq counts",
  "neuroendocrine RNA-seq raw counts"
)

# 定义搜索条件
search_criteria <- list(
  min_samples_per_group = 3,  # 每组至少3个生物学重复
  data_type = "raw_counts",   # 必须是原始计数
  sample_type = "wild_type",  # 野生型样本
  exclude_interventions = c("CRISPR", "knockout", "knockdown", "overexpression"),
  required_format = "counts_matrix"  # 必须是计数矩阵格式
)

# 1. GEO数据库搜索函数
search_geo_datasets <- function(keywords, min_samples = 3) {
  cat("🔍 在GEO数据库中搜索神经内分泌肿瘤数据集...\n")
  
  all_results <- list()
  
  for (keyword in keywords) {
    cat("搜索关键词:", keyword, "\n")
    
    # 使用entrez搜索GEO
    search_term <- paste0(keyword, " AND \"Expression profiling by high throughput sequencing\"[DataSet Type]")
    
    tryCatch({
      # 搜索GEO数据集
      search_result <- entrez_search(db = "gds", 
                                   term = search_term, 
                                   retmax = 50)
      
      if (length(search_result$ids) > 0) {
        # 获取详细信息
        summaries <- entrez_summary(db = "gds", id = search_result$ids)
        
        for (i in 1:length(summaries)) {
          summary <- summaries[[i]]
          
          # 检查样本数量
          if (summary$n_samples >= min_samples) {
            # 检查是否包含计数数据
            if (grepl("counts|HTSeq|raw", summary$description, ignore.case = TRUE)) {
              
              dataset_info <- list(
                accession = summary$accession,
                title = summary$title,
                description = summary$description,
                n_samples = summary$n_samples,
                organism = summary$organism,
                platform = summary$platform,
                keywords = keyword
              )
              
              all_results[[length(all_results) + 1]] <- dataset_info
            }
          }
        }
      }
    }, error = function(e) {
      cat("搜索", keyword, "时出错:", e$message, "\n")
    })
    
    # 避免请求过于频繁
    Sys.sleep(1)
  }
  
  return(all_results)
}

# 2. 验证数据集质量
validate_dataset <- function(geo_id) {
  cat("验证数据集:", geo_id, "\n")
  
  tryCatch({
    # 下载数据集信息
    gse <- getGEO(geo_id, GSEMatrix = FALSE)
    
    # 检查样本信息
    samples <- gse@header$samples
    n_samples <- length(samples)
    
    # 检查是否有足够的样本
    if (n_samples < 6) {  # 至少需要两组，每组3个样本
      return(list(valid = FALSE, reason = "样本数量不足"))
    }
    
    # 检查数据类型
    platform <- gse@header$platform
    if (!grepl("RNA-seq|sequencing", platform, ignore.case = TRUE)) {
      return(list(valid = FALSE, reason = "非RNA-seq数据"))
    }
    
    # 检查是否有计数数据
    if (!grepl("counts|HTSeq", platform, ignore.case = TRUE)) {
      return(list(valid = FALSE, reason = "非计数数据"))
    }
    
    # 检查样本类型
    sample_types <- unique(samples$source_name_ch1)
    if (any(grepl("CRISPR|knockout|knockdown|overexpression", 
                  sample_types, ignore.case = TRUE))) {
      return(list(valid = FALSE, reason = "包含基因干预样本"))
    }
    
    return(list(
      valid = TRUE, 
      n_samples = n_samples,
      sample_types = sample_types,
      platform = platform
    ))
    
  }, error = function(e) {
    return(list(valid = FALSE, reason = paste("验证失败:", e$message)))
  })
}

# 3. 下载和预处理数据
download_and_process_dataset <- function(geo_id, output_dir = "data/raw") {
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
    
    # 检查数据格式
    if (any(expr_matrix < 0)) {
      cat("警告: 检测到负值，可能不是原始计数数据\n")
    }
    
    if (any(expr_matrix != floor(expr_matrix))) {
      cat("警告: 检测到非整数值，可能不是原始计数数据\n")
    }
    
    # 保存数据
    saveRDS(expr_matrix, file.path(output_dir, paste0(geo_id, "_expression.rds")))
    saveRDS(pheno_data, file.path(output_dir, paste0(geo_id, "_phenotype.rds")))
    
    # 保存为CSV格式（便于查看）
    write.csv(expr_matrix, file.path(output_dir, paste0(geo_id, "_expression.csv")))
    write.csv(pheno_data, file.path(output_dir, paste0(geo_id, "_phenotype.csv")))
    
    cat("✅ 数据集", geo_id, "下载完成\n")
    cat("   表达矩阵维度:", dim(expr_matrix), "\n")
    cat("   样本信息维度:", dim(pheno_data), "\n")
    
    return(list(
      success = TRUE,
      expression = expr_matrix,
      metadata = pheno_data,
      file_path = output_dir
    ))
    
  }, error = function(e) {
    cat("❌ 下载数据集", geo_id, "失败:", e$message, "\n")
    return(list(success = FALSE, error = e$message))
  })
}

# 4. 主搜索和下载流程
collect_neta_data <- function(output_dir = "data/raw") {
  cat("🧬 开始收集神经内分泌肿瘤Bulk-RNA-seq数据\n")
  cat("=" %R% 50, "\n")
  
  # 搜索数据集
  search_results <- search_geo_datasets(search_keywords, min_samples = 6)
  
  if (length(search_results) == 0) {
    cat("❌ 未找到符合条件的数据集\n")
    return(NULL)
  }
  
  cat("📊 找到", length(search_results), "个潜在数据集\n")
  
  # 验证和下载数据集
  valid_datasets <- list()
  
  for (result in search_results) {
    geo_id <- result$accession
    
    # 验证数据集
    validation <- validate_dataset(geo_id)
    
    if (validation$valid) {
      cat("✅ 数据集", geo_id, "验证通过\n")
      
      # 下载数据
      download_result <- download_and_process_dataset(geo_id, output_dir)
      
      if (download_result$success) {
        valid_datasets[[length(valid_datasets) + 1]] <- list(
          geo_id = geo_id,
          info = result,
          validation = validation,
          data = download_result
        )
      }
    } else {
      cat("❌ 数据集", geo_id, "验证失败:", validation$reason, "\n")
    }
  }
  
  # 生成数据收集报告
  generate_collection_report(valid_datasets, output_dir)
  
  cat("🎉 数据收集完成！\n")
  cat("   成功下载", length(valid_datasets), "个数据集\n")
  
  return(valid_datasets)
}

# 5. 生成数据收集报告
generate_collection_report <- function(datasets, output_dir) {
  cat("📝 生成数据收集报告...\n")
  
  report_file <- file.path(output_dir, "data_collection_report.txt")
  
  sink(report_file)
  cat("NETA数据收集报告\n")
  cat("生成时间:", Sys.time(), "\n")
  cat("=" %R% 50, "\n\n")
  
  for (i in 1:length(datasets)) {
    dataset <- datasets[[i]]
    cat("数据集", i, ":\n")
    cat("  GEO ID:", dataset$geo_id, "\n")
    cat("  标题:", dataset$info$title, "\n")
    cat("  样本数:", dataset$validation$n_samples, "\n")
    cat("  样本类型:", paste(dataset$validation$sample_types, collapse = ", "), "\n")
    cat("  平台:", dataset$validation$platform, "\n")
    cat("  表达矩阵维度:", dim(dataset$data$expression), "\n")
    cat("\n")
  }
  
  sink()
  
  cat("✅ 报告已保存到:", report_file, "\n")
}

# 6. 手动添加已知数据集
add_known_datasets <- function() {
  # 一些已知的神经内分泌肿瘤数据集（需要手动验证）
  known_datasets <- c(
    "GSE123456",  # 示例ID，需要替换为实际ID
    "GSE789012",  # 示例ID，需要替换为实际ID
    # 添加更多已知的数据集ID
  )
  
  cat("📋 已知的神经内分泌肿瘤数据集:\n")
  for (geo_id in known_datasets) {
    cat("  -", geo_id, "\n")
  }
  
  return(known_datasets)
}

# 7. 数据质量检查
quality_check <- function(expr_matrix, metadata) {
  cat("🔍 进行数据质量检查...\n")
  
  # 检查1: 数据类型
  if (any(expr_matrix < 0)) {
    cat("❌ 警告: 检测到负值\n")
  } else {
    cat("✅ 无负值\n")
  }
  
  # 检查2: 整数值
  if (any(expr_matrix != floor(expr_matrix))) {
    cat("❌ 警告: 检测到非整数值\n")
  } else {
    cat("✅ 所有值均为整数\n")
  }
  
  # 检查3: 零值比例
  zero_proportion <- sum(expr_matrix == 0) / length(expr_matrix)
  cat("📊 零值比例:", round(zero_proportion * 100, 2), "%\n")
  
  # 检查4: 样本质量
  sample_totals <- colSums(expr_matrix)
  cat("📊 样本总计数范围:", range(sample_totals), "\n")
  
  # 检查5: 基因检测
  detected_genes <- rowSums(expr_matrix > 0)
  cat("📊 检测到表达的基因数:", sum(detected_genes > 0), "\n")
  
  return(list(
    has_negatives = any(expr_matrix < 0),
    has_non_integers = any(expr_matrix != floor(expr_matrix)),
    zero_proportion = zero_proportion,
    sample_range = range(sample_totals),
    detected_genes = sum(detected_genes > 0)
  ))
}

# 8. 示例使用
if (FALSE) {  # 设置为TRUE来运行
  # 开始数据收集
  datasets <- collect_neta_data()
  
  # 对每个数据集进行质量检查
  for (dataset in datasets) {
    cat("检查数据集:", dataset$geo_id, "\n")
    quality_check(dataset$data$expression, dataset$data$metadata)
    cat("\n")
  }
}

cat("📋 NETA数据收集脚本已加载\n")
cat("使用方法:\n")
cat("1. 运行 collect_neta_data() 开始自动搜索和下载\n")
cat("2. 运行 add_known_datasets() 查看已知数据集列表\n")
cat("3. 手动下载特定数据集: download_and_process_dataset('GSE_ID')\n")
cat("\n")
cat("⚠️  注意: 请确保网络连接稳定，下载过程可能需要较长时间\n")
