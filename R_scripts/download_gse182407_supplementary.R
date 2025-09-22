#!/usr/bin/env Rscript

# 下载GSE182407的补充数据文件
# 作者: NETA团队
# 日期: 2024-01-15

# 设置工作目录
setwd("/Users/Apple/Desktop/pcatools/NETA")

# 创建输出目录
if (!dir.exists("data/raw/GSE182407/supplementary")) {
  dir.create("data/raw/GSE182407/supplementary", recursive = TRUE)
}

# 下载补充数据文件
download_supplementary_files <- function() {
  cat("=== 下载GSE182407补充数据文件 ===\n")
  
  # 样本ID和对应的文件名
  sample_files <- c(
    "GSM5528434" = "GSM5528434_LN_C1_processed_data.txt.gz",
    "GSM5528435" = "GSM5528435_LN_C2_processed_data.txt.gz", 
    "GSM5528436" = "GSM5528436_LN_C3_processed_data.txt.gz",
    "GSM5528437" = "GSM5528437_LN_Y09_1_processed_data.txt.gz",
    "GSM5528438" = "GSM5528438_LN_Y09_2_processed_data.txt.gz",
    "GSM5528439" = "GSM5528439_LN_Y09_3_processed_data.txt.gz",
    "GSM5528440" = "GSM5528440_LN_Y99_1_processed_data.txt.gz",
    "GSM5528441" = "GSM5528441_LN_Y99_2_processed_data.txt.gz",
    "GSM5528442" = "GSM5528442_LN_Y99_3_processed_data.txt.gz",
    "GSM5528443" = "GSM5528443_DU_C1_processed_data.txt.gz",
    "GSM5528444" = "GSM5528444_DU_C2_processed_data.txt.gz",
    "GSM5528445" = "GSM5528445_DU_C3_processed_data.txt.gz",
    "GSM5528446" = "GSM5528446_DU_Y09_1_processed_data.txt.gz",
    "GSM5528447" = "GSM5528447_DU_Y09_2_processed_data.txt.gz",
    "GSM5528448" = "GSM5528448_DU_Y09_3_processed_data.txt.gz",
    "GSM5528449" = "GSM5528449_DU_Y99_1_processed_data.txt.gz",
    "GSM5528450" = "GSM5528450_DU_Y99_2_processed_data.txt.gz",
    "GSM5528451" = "GSM5528451_DU_Y99_3_processed_data.txt.gz",
    "GSM5528452" = "GSM5528452_H660_E_1_processed_data.txt.gz",
    "GSM5528453" = "GSM5528453_H660_E_2_processed_data.txt.gz",
    "GSM5528454" = "GSM5528454_H660_E_3_processed_data.txt.gz",
    "GSM5528455" = "GSM5528455_H660_Y_1_processed_data.txt.gz",
    "GSM5528456" = "GSM5528456_H660_Y_2_processed_data.txt.gz",
    "GSM5528457" = "GSM5528457_H660_Y_3_processed_data.txt.gz"
  )
  
  # 下载每个文件
  for (sample_id in names(sample_files)) {
    filename <- sample_files[sample_id]
    url <- paste0("https://www.ncbi.nlm.nih.gov/geo/download/?acc=", sample_id, "&format=file&file=", filename)
    local_path <- file.path("data/raw/GSE182407/supplementary", filename)
    
    cat("下载", sample_id, "...\n")
    
    tryCatch({
      download.file(url, local_path, method = "wget", quiet = TRUE)
      cat("✅", sample_id, "下载成功\n")
    }, error = function(e) {
      cat("❌", sample_id, "下载失败:", e$message, "\n")
    })
  }
  
  cat("✅ 补充数据文件下载完成\n")
}

# 处理下载的数据文件
process_supplementary_files <- function() {
  cat("\n=== 处理补充数据文件 ===\n")
  
  # 读取所有数据文件
  data_files <- list.files("data/raw/GSE182407/supplementary", pattern = "*.txt.gz", full.names = TRUE)
  
  if (length(data_files) == 0) {
    cat("❌ 没有找到数据文件\n")
    return(NULL)
  }
  
  cat("找到", length(data_files), "个数据文件\n")
  
  # 读取第一个文件查看格式
  first_file <- data_files[1]
  cat("检查文件格式:", basename(first_file), "\n")
  
  # 读取第一个文件
  first_data <- read.table(first_file, header = TRUE, sep = "\t", stringsAsFactors = FALSE)
  cat("第一个文件维度:", dim(first_data), "\n")
  cat("第一个文件列名:", colnames(first_data), "\n")
  cat("第一个文件前几行:\n")
  print(head(first_data))
  
  # 合并所有数据
  all_data <- list()
  
  for (file in data_files) {
    sample_name <- gsub(".*GSM(\\d+)_.*", "GSM\\1", basename(file))
    cat("处理", sample_name, "...\n")
    
    tryCatch({
      data <- read.table(file, header = TRUE, sep = "\t", stringsAsFactors = FALSE)
      
      # 假设第一列是基因ID，第二列是计数
      if (ncol(data) >= 2) {
        # 使用第一列作为基因ID，第二列作为计数
        gene_counts <- data[, 2]
        names(gene_counts) <- data[, 1]
        all_data[[sample_name]] <- gene_counts
        cat("✅", sample_name, "处理成功，", length(gene_counts), "个基因\n")
      } else {
        cat("❌", sample_name, "文件格式不正确\n")
      }
    }, error = function(e) {
      cat("❌", sample_name, "处理失败:", e$message, "\n")
    })
  }
  
  if (length(all_data) == 0) {
    cat("❌ 没有成功处理任何数据文件\n")
    return(NULL)
  }
  
  # 合并数据
  cat("\n合并数据...\n")
  
  # 获取所有基因ID
  all_genes <- unique(unlist(lapply(all_data, names)))
  cat("总基因数:", length(all_genes), "\n")
  
  # 创建表达矩阵
  expr_matrix <- matrix(0, nrow = length(all_genes), ncol = length(all_data))
  rownames(expr_matrix) <- all_genes
  colnames(expr_matrix) <- names(all_data)
  
  # 填充数据
  for (sample in names(all_data)) {
    expr_matrix[names(all_data[[sample]]), sample] <- all_data[[sample]]
  }
  
  cat("表达矩阵维度:", dim(expr_matrix), "\n")
  cat("数据范围:", range(expr_matrix), "\n")
  cat("数据中位数:", median(expr_matrix), "\n")
  
  # 保存合并后的数据
  write.csv(expr_matrix, "data/raw/GSE182407/GSE182407_expression_matrix_processed.csv", row.names = TRUE)
  
  cat("✅ 数据合并完成\n")
  
  return(expr_matrix)
}

# 主函数
main <- function() {
  cat("=== GSE182407补充数据处理开始 ===\n")
  
  # 下载补充文件
  download_supplementary_files()
  
  # 处理数据
  expr_matrix <- process_supplementary_files()
  
  if (!is.null(expr_matrix)) {
    cat("\n✅ GSE182407数据处理完成！\n")
    cat("表达矩阵维度:", dim(expr_matrix), "\n")
    cat("数据已保存到: data/raw/GSE182407/GSE182407_expression_matrix_processed.csv\n")
  } else {
    cat("\n❌ GSE182407数据处理失败\n")
  }
}

# 运行主函数
main()
