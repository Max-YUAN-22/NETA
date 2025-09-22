#!/usr/bin/env Rscript

# 全网搜索神经内分泌癌Bulk RNA-seq数据集
# 作者: NETA团队
# 日期: 2024-01-15

# 加载必要的包
suppressPackageStartupMessages({
  library(GEOquery)
  library(Biobase)
  library(httr)
  library(jsonlite)
  library(XML)
})

# 设置工作目录
setwd("/Users/Apple/Desktop/pcatools/NETA")

# 创建输出目录
if (!dir.exists("data/search_results")) {
  dir.create("data/search_results", recursive = TRUE)
}

# 搜索GEO数据库中的神经内分泌癌RNA-seq数据集
search_geo_neuroendocrine_datasets <- function() {
  cat("=== 搜索GEO数据库中的神经内分泌癌RNA-seq数据集 ===\n")
  
  # 定义搜索关键词
  search_terms <- c(
    "neuroendocrine tumor RNA-seq",
    "neuroendocrine carcinoma RNA-seq", 
    "pancreatic neuroendocrine RNA-seq",
    "lung neuroendocrine RNA-seq",
    "gastrointestinal neuroendocrine RNA-seq",
    "NET RNA-seq",
    "NEC RNA-seq",
    "pheochromocytoma RNA-seq",
    "paraganglioma RNA-seq",
    "carcinoid RNA-seq"
  )
  
  all_datasets <- list()
  
  for (term in search_terms) {
    cat("\n搜索关键词:", term, "\n")
    
    tryCatch({
      # 使用GEOquery搜索
      search_results <- getGEO(term, GSEMatrix = FALSE)
      
      if (!is.null(search_results)) {
        cat("找到", length(search_results), "个数据集\n")
        
        for (i in 1:length(search_results)) {
          gse_id <- names(search_results)[i]
          gse_data <- search_results[[i]]
          
          # 提取基本信息
          dataset_info <- extract_dataset_info(gse_id, gse_data)
          if (!is.null(dataset_info)) {
            all_datasets[[gse_id]] <- dataset_info
          }
        }
      }
    }, error = function(e) {
      cat("搜索失败:", e$message, "\n")
    })
  }
  
  return(all_datasets)
}

# 提取数据集信息
extract_dataset_info <- function(gse_id, gse_data) {
  tryCatch({
    # 获取基本信息
    title <- Meta(gse_data)$title
    summary <- Meta(gse_data)$summary
    type <- Meta(gse_data)$type
    platform <- Meta(gse_data)$platform
    sample_count <- length(Meta(gse_data)$sample_id)
    
    # 检查是否为RNA-seq
    is_rnaseq <- any(grepl("Expression profiling by high throughput sequencing", type, ignore.case = TRUE))
    is_microarray <- any(grepl("Expression profiling by array", type, ignore.case = TRUE))
    
    # 检查神经内分泌癌相关关键词
    net_keywords <- c("neuroendocrine", "NET", "NEC", "carcinoid", "pheochromocytoma", "paraganglioma")
    has_net_keywords <- any(sapply(net_keywords, function(x) grepl(x, paste(title, summary), ignore.case = TRUE)))
    
    # 检查样本数量
    has_sufficient_samples <- sample_count >= 6
    
    # 检查是否有原始计数数据
    has_raw_counts <- any(grepl("raw count|HTSeq|featureCounts|count matrix", 
                               paste(title, summary), ignore.case = TRUE))
    
    # 综合评估
    is_valid <- is_rnaseq && !is_microarray && has_net_keywords && 
                has_sufficient_samples && has_raw_counts
    
    dataset_info <- list(
      geo_id = gse_id,
      title = title,
      summary = substr(summary, 1, 500),
      type = paste(type, collapse = ", "),
      platform = paste(platform, collapse = ", "),
      sample_count = sample_count,
      is_rnaseq = is_rnaseq,
      is_microarray = is_microarray,
      has_net_keywords = has_net_keywords,
      has_sufficient_samples = has_sufficient_samples,
      has_raw_counts = has_raw_counts,
      is_valid = is_valid,
      pubmed_id = Meta(gse_data)$pubmed_id,
      submission_date = Meta(gse_data)$submission_date
    )
    
    cat("  ", gse_id, ":", ifelse(is_valid, "✅ 符合条件", "❌ 不符合条件"), "\n")
    
    return(dataset_info)
    
  }, error = function(e) {
    cat("  ", gse_id, ": 提取信息失败\n")
    return(NULL)
  })
}

# 验证已知的数据集
validate_known_datasets <- function() {
  cat("\n=== 验证已知的神经内分泌癌数据集 ===\n")
  
  # 已知的数据集列表
  known_datasets <- c(
    "GSE117851", "GSE98894", "GSE103174", "GSE114012", "GSE124341",
    "GSE126030", "GSE132608", "GSE140686", "GSE145837", "GSE150316",
    "GSE156405", "GSE160756", "GSE164760", "GSE165552", "GSE171110",
    "GSE180473", "GSE182407", "GSE19830", "GSE30554", "GSE59739",
    "GSE60361", "GSE60436", "GSE71585", "GSE73338", "GSE10245"
  )
  
  valid_datasets <- list()
  
  for (gse_id in known_datasets) {
    cat("验证", gse_id, "...\n")
    
    tryCatch({
      # 获取GEO信息
      gse <- getGEO(gse_id, GSEMatrix = FALSE, destdir = "data/search_results")
      
      if (!is.null(gse)) {
        dataset_info <- extract_dataset_info(gse_id, gse)
        if (!is.null(dataset_info) && dataset_info$is_valid) {
          valid_datasets[[gse_id]] <- dataset_info
        }
      }
    }, error = function(e) {
      cat("  ", gse_id, ": 验证失败\n")
    })
  }
  
  return(valid_datasets)
}

# 搜索新的数据集
search_new_datasets <- function() {
  cat("\n=== 搜索新的神经内分泌癌数据集 ===\n")
  
  # 使用GEO的API搜索
  base_url <- "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi"
  
  # 搜索查询
  queries <- c(
    "neuroendocrine[Title] AND RNA-seq[Title]",
    "neuroendocrine[Title] AND sequencing[Title]",
    "NET[Title] AND RNA-seq[Title]",
    "NEC[Title] AND RNA-seq[Title]",
    "carcinoid[Title] AND RNA-seq[Title]",
    "pheochromocytoma[Title] AND RNA-seq[Title]"
  )
  
  all_gse_ids <- c()
  
  for (query in queries) {
    cat("搜索查询:", query, "\n")
    
    tryCatch({
      # 构建搜索URL
      search_url <- paste0(base_url, "?db=gds&term=", URLencode(query), "&retmax=100&retmode=json")
      
      # 发送请求
      response <- GET(search_url)
      
      if (status_code(response) == 200) {
        content <- content(response, "text")
        data <- fromJSON(content)
        
        if (!is.null(data$esearchresult$idlist)) {
          gse_ids <- data$esearchresult$idlist
          all_gse_ids <- c(all_gse_ids, gse_ids)
          cat("找到", length(gse_ids), "个数据集\n")
        }
      }
    }, error = function(e) {
      cat("搜索失败:", e$message, "\n")
    })
  }
  
  # 去重
  unique_gse_ids <- unique(all_gse_ids)
  cat("总共找到", length(unique_gse_ids), "个唯一的数据集\n")
  
  return(unique_gse_ids)
}

# 主函数
main <- function() {
  cat("=== 全网搜索神经内分泌癌Bulk RNA-seq数据集 ===\n")
  
  # 验证已知数据集
  valid_known <- validate_known_datasets()
  
  # 搜索新数据集
  new_gse_ids <- search_new_datasets()
  
  # 验证新数据集
  valid_new <- list()
  for (gse_id in new_gse_ids[1:min(20, length(new_gse_ids))]) { # 限制验证数量
    if (!gse_id %in% names(valid_known)) {
      cat("验证新数据集", gse_id, "...\n")
      
      tryCatch({
        gse <- getGEO(gse_id, GSEMatrix = FALSE, destdir = "data/search_results")
        if (!is.null(gse)) {
          dataset_info <- extract_dataset_info(gse_id, gse)
          if (!is.null(dataset_info) && dataset_info$is_valid) {
            valid_new[[gse_id]] <- dataset_info
          }
        }
      }, error = function(e) {
        cat("验证失败:", e$message, "\n")
      })
    }
  }
  
  # 合并结果
  all_valid_datasets <- c(valid_known, valid_new)
  
  cat("\n=== 搜索结果总结 ===\n")
  cat("符合条件的数据集数量:", length(all_valid_datasets), "\n")
  
  if (length(all_valid_datasets) > 0) {
    cat("\n符合条件的数据集:\n")
    for (gse_id in names(all_valid_datasets)) {
      info <- all_valid_datasets[[gse_id]]
      cat("  ", gse_id, ":", info$title, "\n")
      cat("    样本数:", info$sample_count, "\n")
      cat("    类型:", info$type, "\n")
      cat("    发表年份:", substr(info$submission_date, 1, 4), "\n")
    }
    
    # 保存结果
    save(all_valid_datasets, file = "data/search_results/valid_neuroendocrine_datasets.RData")
    write.csv(do.call(rbind, lapply(all_valid_datasets, function(x) {
      data.frame(
        geo_id = x$geo_id,
        title = x$title,
        sample_count = x$sample_count,
        type = x$type,
        submission_date = x$submission_date,
        stringsAsFactors = FALSE
      )
    })), "data/search_results/valid_datasets_summary.csv", row.names = FALSE)
    
    cat("\n✅ 搜索结果已保存到 data/search_results/\n")
  } else {
    cat("\n❌ 没有找到符合条件的数据集\n")
  }
}

# 运行主函数
main()
