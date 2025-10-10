#!/usr/bin/env Rscript
# 富集分析脚本

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

# 模拟富集分析结果
set.seed(123)

# 模拟KEGG通路富集结果
kegg_pathways <- c(
  "hsa04010:MAPK signaling pathway",
  "hsa04110:Cell cycle",
  "hsa04151:PI3K-Akt signaling pathway",
  "hsa04014:Ras signaling pathway",
  "hsa04115:p53 signaling pathway",
  "hsa04012:ErbB signaling pathway",
  "hsa04150:mTOR signaling pathway",
  "hsa04020:Calcium signaling pathway"
)

kegg_results <- data.frame(
  pathway_id = sub(":.*", "", kegg_pathways),
  pathway_name = sub(".*:", "", kegg_pathways),
  gene_count = sample(5:50, length(kegg_pathways)),
  pvalue = runif(length(kegg_pathways), 0.001, 0.05),
  padj = runif(length(kegg_pathways), 0.01, 0.1),
  stringsAsFactors = FALSE
)

# 模拟GO富集结果
go_terms <- c(
  "GO:0006915:apoptotic process",
  "GO:0007049:cell cycle",
  "GO:0007165:signal transduction",
  "GO:0008283:cell proliferation",
  "GO:0012501:programmed cell death",
  "GO:0043065:positive regulation of apoptotic process",
  "GO:0043066:negative regulation of apoptotic process",
  "GO:0051726:regulation of cell cycle"
)

go_results <- data.frame(
  term_id = sub(":.*", "", go_terms),
  term_name = sub(".*:", "", go_terms),
  gene_count = sample(3:30, length(go_terms)),
  pvalue = runif(length(go_terms), 0.001, 0.05),
  padj = runif(length(go_terms), 0.01, 0.1),
  stringsAsFactors = FALSE
)

# 创建输出结果
output <- list(
  status = "completed",
  message = "Enrichment analysis completed successfully",
  results = list(
    kegg_results = kegg_results,
    go_results = go_results,
    total_pathways = nrow(kegg_results),
    total_go_terms = nrow(go_results),
    parameters = input_data
  )
)

# 保存结果
jsonlite::write_json(output, opt$output, pretty = TRUE)

cat("Enrichment analysis completed successfully\n")
cat("Output saved to:", opt$output, "\n")
