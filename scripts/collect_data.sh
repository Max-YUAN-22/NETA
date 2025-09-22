#!/bin/bash
# NETA数据收集快速启动脚本

echo "🧬 NETA数据收集启动脚本"
echo "========================"

# 检查R环境
if ! command -v R &> /dev/null; then
    echo "❌ 错误: R未安装。请先安装R"
    exit 1
fi

echo "✅ R环境检查通过"

# 创建数据目录
echo "📁 创建数据目录..."
mkdir -p data/{raw,processed}
mkdir -p logs

echo "✅ 数据目录创建完成"

# 检查网络连接
echo "🌐 检查网络连接..."
if ping -c 1 ncbi.nlm.nih.gov &> /dev/null; then
    echo "✅ 网络连接正常"
else
    echo "⚠️  警告: 网络连接可能有问题，请检查网络设置"
fi

# 创建数据收集日志
log_file="logs/data_collection_$(date +%Y%m%d_%H%M%S).log"
echo "📝 创建日志文件: $log_file"

# 运行数据收集脚本
echo "🚀 开始数据收集..."
echo "开始时间: $(date)" | tee -a "$log_file"

# 运行R脚本
Rscript -e "
# 设置工作目录
setwd('.')

# 加载必要的包
if (!require('GEOquery', quietly = TRUE)) {
    if (!require('BiocManager', quietly = TRUE)) {
        install.packages('BiocManager')
    }
    BiocManager::install('GEOquery')
    library(GEOquery)
}

# 运行数据收集
source('R_scripts/known_datasets.R')

# 开始处理已知数据集
cat('开始处理已知数据集...\n')
datasets <- process_known_datasets()

if (length(datasets) > 0) {
    cat('成功处理', length(datasets), '个数据集\n')
    
    # 创建数据清单
    inventory <- create_data_inventory()
    cat('数据清单已创建\n')
} else {
    cat('未找到符合条件的数据集\n')
}

cat('数据收集完成\n')
" 2>&1 | tee -a "$log_file"

# 检查结果
if [ -f "data/raw/data_inventory.csv" ]; then
    echo "✅ 数据收集完成！"
    echo "📊 数据清单:"
    cat data/raw/data_inventory.csv
else
    echo "❌ 数据收集失败，请检查日志文件: $log_file"
fi

echo "结束时间: $(date)" | tee -a "$log_file"
echo "📝 完整日志保存在: $log_file"

echo ""
echo "🎉 NETA数据收集脚本执行完成！"
echo ""
echo "📋 下一步:"
echo "1. 检查数据质量: 查看 data/raw/ 目录中的文件"
echo "2. 运行数据处理: Rscript R_scripts/data_processing.R"
echo "3. 启动Shiny应用: ./start_neta.sh"
echo ""
echo "💡 提示: 如果遇到网络问题，可以稍后重试或手动下载数据集"
