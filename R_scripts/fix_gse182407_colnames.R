#!/usr/bin/env Rscript

# 最终修复GSE182407数据处理 - 处理列名问题
# 作者: NETA团队
# 日期: 2024-01-15

# 设置工作目录
setwd("/Users/Apple/Desktop/pcatools/NETA")

# 处理补充数据文件 - 处理列名问题
process_supplementary_files_with_colnames <- function() {
  cat("=== 处理GSE182407数据 - 修复列名问题 ===\n")
  
  # 读取所有数据文件
  data_files <- list.files("data/raw/GSE182407/supplementary", pattern = "*.txt.gz", full.names = TRUE)
  
  if (length(data_files) == 0) {
    cat("❌ 没有找到数据文件\n")
    return(NULL)
  }
  
  cat("找到", length(data_files), "个数据文件\n")
  
  # 合并所有数据
  all_data <- list()
  
  for (file in data_files) {
    sample_name <- gsub(".*GSM(\\d+)_.*", "GSM\\1", basename(file))
    cat("处理", sample_name, "...\n")
    
    tryCatch({
      # 读取数据
      data <- read.table(file, header = TRUE, sep = "\t", stringsAsFactors = FALSE, quote = "")
      
      # 清理列名
      colnames(data) <- gsub('^X\\.', '', colnames(data))
      colnames(data) <- gsub('\\.$', '', colnames(data))
      colnames(data) <- gsub('"', '', colnames(data))
      
      cat("清理后的列名:", colnames(data), "\n")
      
      # 使用Gene_symbol作为基因ID，Frag_count作为计数
      if ("Gene_symbol" %in% colnames(data) && "Frag_count" %in% colnames(data)) {
        # 过滤掉空基因名
        valid_rows <- !is.na(data$Gene_symbol) & data$Gene_symbol != "" & data$Gene_symbol != "NA"
        
        gene_counts <- as.numeric(data$Frag_count[valid_rows])
        names(gene_counts) <- data$Gene_symbol[valid_rows]
        
        all_data[[sample_name]] <- gene_counts
        cat("✅", sample_name, "处理成功，", length(gene_counts), "个基因\n")
      } else {
        cat("❌", sample_name, "文件格式不正确，列名:", colnames(data), "\n")
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
  
  # 检查数据类型
  cat("数据类型:", class(expr_matrix[1,1]), "\n")
  cat("是否为数值:", is.numeric(expr_matrix), "\n")
  
  # 保存合并后的数据
  write.csv(expr_matrix, "data/raw/GSE182407/GSE182407_expression_matrix_final.csv", row.names = TRUE)
  
  cat("✅ 数据合并完成\n")
  
  return(expr_matrix)
}

# 创建表型数据
create_phenotype_data_final <- function() {
  cat("\n=== 创建表型数据 ===\n")
  
  # 基于样本名称创建分组
  sample_names <- c(
    "GSM5528434", "GSM5528435", "GSM5528436",  # LNCaP Control
    "GSM5528437", "GSM5528438", "GSM5528439",  # LNCaP YAP1 KD clone1
    "GSM5528440", "GSM5528441", "GSM5528442",  # LNCaP YAP1 KD clone2
    "GSM5528443", "GSM5528444", "GSM5528445",  # DU145 Control
    "GSM5528446", "GSM5528447", "GSM5528448",  # DU145 YAP1 KD clone1
    "GSM5528449", "GSM5528450", "GSM5528451",  # DU145 YAP1 KD clone2
    "GSM5528452", "GSM5528453", "GSM5528454",  # NCI-H660 Control
    "GSM5528455", "GSM5528456", "GSM5528457"   # NCI-H660 YAP1 OE
  )
  
  # 创建分组
  groups <- c(
    rep("LNCaP_Control", 3),
    rep("LNCaP_YAP1_KD", 6),
    rep("DU145_Control", 3),
    rep("DU145_YAP1_KD", 6),
    rep("NCI-H660_Control", 3),
    rep("NCI-H660_YAP1_OE", 3)
  )
  
  # 创建表型数据框
  pheno_data <- data.frame(
    sample_id = sample_names,
    group = groups,
    cell_line = c(
      rep("LNCaP", 9),
      rep("DU145", 9),
      rep("NCI-H660", 6)
    ),
    treatment = c(
      rep("Control", 3),
      rep("YAP1_KD", 6),
      rep("Control", 3),
      rep("YAP1_KD", 6),
      rep("Control", 3),
      rep("YAP1_OE", 3)
    ),
    stringsAsFactors = FALSE
  )
  
  rownames(pheno_data) <- sample_names
  
  cat("表型数据:\n")
  print(pheno_data)
  
  # 保存表型数据
  write.csv(pheno_data, "data/raw/GSE182407/GSE182407_phenotype_data_final.csv", row.names = TRUE)
  
  cat("✅ 表型数据创建完成\n")
  
  return(pheno_data)
}

# 主函数
main <- function() {
  cat("=== GSE182407数据处理 - 修复列名问题 ===\n")
  
  # 处理数据
  expr_matrix <- process_supplementary_files_with_colnames()
  
  if (!is.null(expr_matrix)) {
    # 创建表型数据
    pheno_data <- create_phenotype_data_final()
    
    cat("\n✅ GSE182407数据处理完成！\n")
    cat("表达矩阵维度:", dim(expr_matrix), "\n")
    cat("表型数据维度:", dim(pheno_data), "\n")
    cat("数据已保存到:\n")
    cat("  - data/raw/GSE182407/GSE182407_expression_matrix_final.csv\n")
    cat("  - data/raw/GSE182407/GSE182407_phenotype_data_final.csv\n")
    
    # 显示样本分组
    cat("\n样本分组:\n")
    print(table(pheno_data$group))
    
  } else {
    cat("\n❌ GSE182407数据处理失败\n")
  }
}

# 运行主函数
main()
