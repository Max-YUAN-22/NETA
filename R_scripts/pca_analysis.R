#!/usr/bin/env Rscript
# PCA分析脚本

library(optparse)
library(jsonlite)

# 解析命令行参数
option_list <- list(
  make_option(c("--input"), type="character", default="input.json",
              help="输入JSON文件路径"),
  make_option(c("--output"), type="character", default="output.json",
              help="输出JSON文件路径")
)

opt_parser <- OptionParser(option_list=option_list)
opt <- parse_args(opt_parser)

# 读取输入参数
input_data <- jsonlite::fromJSON(opt$input)

# 模拟PCA分析
set.seed(123)
n_samples <- 50
n_genes <- 1000

# 生成模拟表达矩阵
expr_matrix <- matrix(rnorm(n_samples * n_genes), nrow = n_genes, ncol = n_samples)
rownames(expr_matrix) <- paste0("GENE_", sprintf("%04d", 1:n_genes))
colnames(expr_matrix) <- paste0("SAMPLE_", sprintf("%03d", 1:n_samples))

# 执行PCA
pca_result <- prcomp(t(expr_matrix), scale = TRUE)

# 提取前两个主成分
pca_data <- data.frame(
  PC1 = pca_result$x[, 1],
  PC2 = pca_result$x[, 2],
  sample_id = colnames(expr_matrix),
  group = sample(c("Group1", "Group2"), n_samples, replace = TRUE),
  stringsAsFactors = FALSE
)

# 计算解释方差比例
explained_variance_ratio <- pca_result$sdev^2 / sum(pca_result$sdev^2)

# 创建输出结果
output <- list(
  status = "completed",
  message = "PCA analysis completed successfully",
  results = list(
    pca_data = pca_data,
    explained_variance_ratio = explained_variance_ratio[1:2],
    n_components = input_data$n_components,
    n_samples = n_samples,
    n_genes = n_genes,
    parameters = input_data
  )
)

# 保存结果
jsonlite::write_json(output, opt$output, pretty = TRUE)

cat("PCA analysis completed successfully\n")
cat("Output saved to:", opt$output, "\n")
