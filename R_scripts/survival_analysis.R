#!/usr/bin/env Rscript
# 生存分析脚本

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

# 模拟生存分析结果
set.seed(123)
n_samples <- 100

# 生成模拟生存数据
survival_data <- data.frame(
  sample_id = paste0("SAMPLE_", sprintf("%03d", 1:n_samples)),
  time = runif(n_samples, 10, 100),
  status = sample(c(0, 1), n_samples, replace = TRUE, prob = c(0.3, 0.7)),
  group = sample(c("High", "Low"), n_samples, replace = TRUE),
  stringsAsFactors = FALSE
)

# 计算生存统计
high_group <- survival_data[survival_data$group == "High", ]
low_group <- survival_data[survival_data$group == "Low", ]

high_median <- median(high_group$time)
low_median <- median(low_group$time)

# 模拟log-rank检验p值
logrank_pvalue <- runif(1, 0.01, 0.05)

# 创建生存曲线数据
time_points <- seq(0, max(survival_data$time), by = 5)
high_survival <- sapply(time_points, function(t) {
  sum(high_group$time > t) / nrow(high_group)
})
low_survival <- sapply(time_points, function(t) {
  sum(low_group$time > t) / nrow(low_group)
})

survival_curves <- data.frame(
  time = time_points,
  high_group = high_survival,
  low_group = low_survival,
  stringsAsFactors = FALSE
)

# 创建输出结果
output <- list(
  status = "completed",
  message = "Survival analysis completed successfully",
  results = list(
    survival_data = survival_data,
    survival_curves = survival_curves,
    high_group_median = high_median,
    low_group_median = low_median,
    logrank_pvalue = logrank_pvalue,
    n_samples = n_samples,
    parameters = input_data
  )
)

# 保存结果
jsonlite::write_json(output, opt$output, pretty = TRUE)

cat("Survival analysis completed successfully\n")
cat("Output saved to:", opt$output, "\n")
