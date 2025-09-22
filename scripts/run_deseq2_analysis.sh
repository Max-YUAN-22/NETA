#!/bin/bash

# NETA DESeq2分析运行脚本
# 功能: 运行DESeq2差异表达分析

set -e

echo "=== NETA DESeq2分析开始 ==="
echo "开始时间: $(date)"

# 设置工作目录
cd /Users/Apple/Desktop/pcatools/NETA

# 检查R是否安装
if ! command -v R &> /dev/null; then
    echo "错误: R未安装，请先安装R"
    exit 1
fi

# 检查必要的R包
echo "检查R包依赖..."
Rscript -e "
required_packages <- c('DESeq2', 'ggplot2', 'pheatmap', 'VennDiagram', 'EnhancedVolcano', 'dplyr', 'readr', 'tidyr')
missing_packages <- required_packages[!sapply(required_packages, requireNamespace, quietly = TRUE)]

if (length(missing_packages) > 0) {
  cat('安装缺失的R包:', paste(missing_packages, collapse = ', '), '\n')
  install.packages(missing_packages, repos = 'https://cran.rstudio.com/')
} else {
  cat('所有必要的R包已安装\n')
}
"

# 运行DESeq2分析
echo "开始DESeq2分析..."
Rscript R_scripts/deseq2_analysis.R

# 检查分析结果
if [ -d "data/processed/analysis_results/deseq2" ]; then
    echo "DESeq2分析结果:"
    ls -la data/processed/analysis_results/deseq2/
    
    echo "分析完成时间: $(date)"
    echo "结果保存在: data/processed/analysis_results/deseq2/"
else
    echo "错误: DESeq2分析失败"
    exit 1
fi

echo "=== DESeq2分析完成 ==="
