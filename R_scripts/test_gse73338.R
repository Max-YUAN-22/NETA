#!/usr/bin/env Rscript

# 测试GSE73338数据分析
# 作者: NETA团队
# 日期: 2024-01-15

# 加载必要的包
suppressPackageStartupMessages({
  library(limma)
  library(ggplot2)
})

# 设置工作目录
setwd("/Users/Apple/Desktop/pcatools/NETA")

# 创建输出目录
if (!dir.exists("data/processed/analysis_results/deseq2")) {
  dir.create("data/processed/analysis_results/deseq2", recursive = TRUE)
}

# 测试分析函数
test_analysis <- function(geo_id) {
  cat("开始测试分析数据集:", geo_id, "\n")
  
  tryCatch({
    # 读取数据
    expr_file <- paste0("data/raw/", geo_id, "_expression_matrix.csv")
    pheno_file <- paste0("data/raw/", geo_id, "_phenotype_data.csv")
    
    # 读取表达矩阵
    expr_data <- read.csv(expr_file, row.names = 1, check.names = FALSE)
    cat("  - 表达矩阵:", nrow(expr_data), "基因 x", ncol(expr_data), "样本\n")
    
    # 读取表型数据
    pheno_data <- read.csv(pheno_file, row.names = 1, check.names = FALSE)
    cat("  - 表型数据:", nrow(pheno_data), "样本\n")
    
    # 从title列提取分组信息
    titles <- as.character(pheno_data$title)
    
    # 提取分组
    groups <- sapply(titles, function(x) {
      if (grepl("Non-functional", x, ignore.case = TRUE)) return("Non_functional")
      if (grepl("Insulinoma", x, ignore.case = TRUE)) return("Insulinoma")
      if (grepl("Normal pancreas", x, ignore.case = TRUE)) return("Normal")
      if (grepl("Normal pancreas islet", x, ignore.case = TRUE)) return("Normal")
      if (grepl("Functional", x, ignore.case = TRUE)) return("Functional")
      if (grepl("Metastases", x, ignore.case = TRUE)) return("Metastases")
      return("Other")
    })
    
    cat("  - 分组:", paste(unique(groups), collapse = ", "), "\n")
    cat("  - 样本数:", paste(table(groups), collapse = ", "), "\n")
    
    # 过滤掉样本数不足的分组
    group_counts <- table(groups)
    valid_groups <- names(group_counts)[group_counts >= 3]
    
    cat("  - 有效分组:", paste(valid_groups, collapse = ", "), "\n")
    
    if (length(valid_groups) < 2) {
      cat("❌", geo_id, "有效分组不足，跳过分析\n")
      return(FALSE)
    }
    
    # 只保留有效分组的样本
    valid_samples <- names(groups)[groups %in% valid_groups]
    expr_data <- expr_data[, valid_samples]
    groups <- groups[valid_samples]
    
    cat("  - 过滤后分组:", paste(unique(groups), collapse = ", "), "\n")
    cat("  - 过滤后样本数:", paste(table(groups), collapse = ", "), "\n")
    
    # 创建设计矩阵
    design <- model.matrix(~ 0 + factor(groups))
    colnames(design) <- levels(factor(groups))
    
    cat("  - 设计矩阵列名:", paste(colnames(design), collapse = ", "), "\n")
    
    # 拟合线性模型
    fit <- lmFit(expr_data, design)
    cat("  - 线性模型拟合成功\n")
    
    # 创建对比矩阵 - 比较Non_functional vs Normal
    if ("Non_functional" %in% colnames(design) && "Normal" %in% colnames(design)) {
      contrasts <- makeContrasts(
        Non_functional_vs_Normal = Non_functional - Normal,
        levels = design
      )
      
      cat("  - 对比矩阵创建成功\n")
      
      # 拟合对比
      fit2 <- contrasts.fit(fit, contrasts)
      fit2 <- eBayes(fit2)
      
      cat("  - 对比拟合成功\n")
      
      # 获取结果
      res <- topTable(fit2, coef = 1, number = Inf, sort.by = "P")
      
      cat("  - 结果获取成功\n")
      
      # 过滤显著基因
      sig_genes <- res[res$adj.P.Val < 0.05 & abs(res$logFC) > 1, ]
      cat("  - 显著差异基因:", nrow(sig_genes), "\n")
      
      # 创建输出目录
      output_dir <- paste0("data/processed/analysis_results/deseq2/", geo_id)
      if (!dir.exists(output_dir)) {
        dir.create(output_dir, recursive = TRUE)
      }
      
      # 保存结果
      write.csv(res, file = paste0(output_dir, "/limma_results.csv"))
      write.csv(sig_genes, file = paste0(output_dir, "/significant_genes.csv"))
      
      cat("✅", geo_id, "分析完成\n")
      cat("  - 输出目录:", output_dir, "\n")
      cat("  - 显著基因:", nrow(sig_genes), "\n")
      cat("  - 上调基因:", sum(sig_genes$logFC > 1, na.rm = TRUE), "\n")
      cat("  - 下调基因:", sum(sig_genes$logFC < -1, na.rm = TRUE), "\n\n")
      
      return(TRUE)
    } else {
      cat("❌", geo_id, "缺少必要的分组，跳过分析\n")
      return(FALSE)
    }
    
  }, error = function(e) {
    cat("❌", geo_id, "分析失败:", e$message, "\n\n")
    return(FALSE)
  })
}

# 主程序
cat("=== 测试GSE73338分析 ===\n")

# 分析GSE73338
geo_id <- "GSE73338"

if (test_analysis(geo_id)) {
  cat("✅ GSE73338分析成功完成！\n")
} else {
  cat("❌ GSE73338分析失败\n")
}

cat("\n所有结果已保存到 data/processed/analysis_results/deseq2/ 目录\n")
