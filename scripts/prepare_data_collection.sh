#!/bin/bash
# NETA数据收集准备脚本 - 等待2TB硬盘连接后使用

echo "🧬 NETA数据收集准备脚本"
echo "========================"
echo "等待2TB硬盘连接后开始数据收集"
echo ""

# 检查硬盘连接状态
check_disk_space() {
    echo "🔍 检查磁盘空间..."
    
    # 检查是否有2TB或更大的硬盘
    available_space=$(df -h . | awk 'NR==2 {print $4}')
    total_space=$(df -h . | awk 'NR==2 {print $2}')
    
    echo "当前可用空间: $available_space"
    echo "总空间: $total_space"
    
    # 检查是否有足够的空间（至少1.5TB）
    available_gb=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
    
    if [ "$available_gb" -gt 1500 ]; then
        echo "✅ 磁盘空间充足，可以开始数据收集"
        return 0
    else
        echo "❌ 磁盘空间不足，请连接2TB硬盘"
        return 1
    fi
}

# 创建数据收集目录结构
create_directory_structure() {
    echo "📁 创建数据收集目录结构..."
    
    # 创建主目录
    mkdir -p data/{raw,processed,backup}
    mkdir -p logs
    mkdir -p scripts
    mkdir -p docs
    
    # 创建子目录
    mkdir -p data/raw/{geo,tcga,sra,arrayexpress}
    mkdir -p data/processed/{expression,metadata,results,quality}
    mkdir -p data/backup/{daily,weekly,monthly}
    
    echo "✅ 目录结构创建完成"
}

# 准备数据收集环境
prepare_environment() {
    echo "🔧 准备数据收集环境..."
    
    # 检查R环境
    if ! command -v R &> /dev/null; then
        echo "❌ 错误: R未安装"
        exit 1
    fi
    
    # 检查网络连接
    if ping -c 1 ncbi.nlm.nih.gov &> /dev/null; then
        echo "✅ 网络连接正常"
    else
        echo "⚠️  警告: 网络连接可能有问题"
    fi
    
    # 创建R配置文件
    cat > .Rprofile << 'EOF'
# NETA数据收集R配置
options(repos = c(CRAN = "https://cran.rstudio.com/"))
options(timeout = 300)  # 增加超时时间

# 设置工作目录
if (file.exists("data")) {
  setwd(".")
}

# 加载常用包
if (require("GEOquery", quietly = TRUE)) {
  cat("GEOquery已加载\n")
}
EOF
    
    echo "✅ 环境准备完成"
}

# 创建数据收集日志
create_logging_system() {
    echo "📝 创建日志系统..."
    
    log_file="logs/data_collection_$(date +%Y%m%d_%H%M%S).log"
    
    cat > "$log_file" << EOF
NETA数据收集日志
开始时间: $(date)
硬盘空间: $(df -h . | awk 'NR==2 {print $2 " " $4}')
网络状态: $(ping -c 1 ncbi.nlm.nih.gov > /dev/null 2>&1 && echo "正常" || echo "异常")
========================================

EOF
    
    echo "✅ 日志文件创建: $log_file"
}

# 创建数据收集脚本
create_collection_script() {
    echo "📜 创建数据收集脚本..."
    
    cat > scripts/start_data_collection.sh << 'EOF'
#!/bin/bash
# NETA数据收集启动脚本

echo "🚀 开始NETA数据收集..."
echo "开始时间: $(date)"

# 设置日志文件
log_file="logs/data_collection_$(date +%Y%m%d_%H%M%S).log"

# 运行R数据收集脚本
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

# 运行真实数据集收集
source('R_scripts/real_datasets.R')

# 开始处理真实数据集
cat('开始处理真实存在的神经内分泌肿瘤数据集...\n')
datasets <- process_real_datasets()

if (length(datasets) > 0) {
    cat('成功处理', length(datasets), '个数据集\n')
    
    # 创建数据清单
    inventory <- create_real_data_inventory()
    cat('真实数据集清单已创建\n')
    
    # 生成数据收集报告
    cat('数据收集完成，生成报告...\n')
} else {
    cat('未找到符合条件的数据集\n')
}

cat('NETA数据收集完成\n')
" 2>&1 | tee -a "$log_file"

echo "结束时间: $(date)"
echo "📝 完整日志保存在: $log_file"
EOF
    
    chmod +x scripts/start_data_collection.sh
    echo "✅ 数据收集脚本创建完成"
}

# 创建数据验证脚本
create_validation_script() {
    echo "🔍 创建数据验证脚本..."
    
    cat > scripts/validate_data.sh << 'EOF'
#!/bin/bash
# NETA数据验证脚本

echo "🔍 开始数据验证..."
echo "验证时间: $(date)"

# 运行R数据验证脚本
Rscript -e "
# 设置工作目录
setwd('.')

# 加载必要的包
library(GEOquery)
library(dplyr)

# 运行数据验证
source('R_scripts/real_datasets.R')

# 验证所有已下载的数据集
validation_results <- list()

# 查找所有下载的数据文件
expression_files <- list.files('data/raw', pattern = '_expression\\.rds$', full.names = TRUE)

for (expr_file in expression_files) {
    geo_id <- stringr::str_extract(basename(expr_file), 'GSE\\\\d+')
    cat('验证数据集:', geo_id, '\n')
    
    # 读取数据
    expr_data <- readRDS(expr_file)
    pheno_file <- file.path('data/raw', paste0(geo_id, '_phenotype.rds'))
    
    if (file.exists(pheno_file)) {
        pheno_data <- readRDS(pheno_file)
        
        # 进行质量评估
        quality_result <- assess_real_data_quality(expr_data, pheno_data, geo_id)
        validation_results[[geo_id]] <- quality_result
    }
}

# 保存验证结果
saveRDS(validation_results, 'data/processed/validation_results.rds')
cat('数据验证完成\n')
"

echo "数据验证完成"
EOF
    
    chmod +x scripts/validate_data.sh
    echo "✅ 数据验证脚本创建完成"
}

# 创建数据备份脚本
create_backup_script() {
    echo "💾 创建数据备份脚本..."
    
    cat > scripts/backup_data.sh << 'EOF'
#!/bin/bash
# NETA数据备份脚本

echo "💾 开始数据备份..."
echo "备份时间: $(date)"

# 创建备份目录
backup_dir="data/backup/daily/$(date +%Y%m%d)"
mkdir -p "$backup_dir"

# 备份原始数据
echo "备份原始数据..."
cp -r data/raw/* "$backup_dir/"

# 备份处理后的数据
echo "备份处理后数据..."
cp -r data/processed/* "$backup_dir/"

# 备份日志
echo "备份日志..."
cp -r logs/* "$backup_dir/"

echo "✅ 数据备份完成: $backup_dir"
EOF
    
    chmod +x scripts/backup_data.sh
    echo "✅ 数据备份脚本创建完成"
}

# 主函数
main() {
    echo "🧬 NETA数据收集准备开始..."
    echo "等待2TB硬盘连接..."
    echo ""
    
    # 检查磁盘空间
    if ! check_disk_space; then
        echo "❌ 请连接2TB硬盘后重新运行此脚本"
        exit 1
    fi
    
    # 创建目录结构
    create_directory_structure
    
    # 准备环境
    prepare_environment
    
    # 创建日志系统
    create_logging_system
    
    # 创建脚本
    create_collection_script
    create_validation_script
    create_backup_script
    
    echo ""
    echo "🎉 NETA数据收集准备完成！"
    echo ""
    echo "📋 下一步操作:"
    echo "1. 运行数据收集: ./scripts/start_data_collection.sh"
    echo "2. 验证数据质量: ./scripts/validate_data.sh"
    echo "3. 备份数据: ./scripts/backup_data.sh"
    echo ""
    echo "💡 提示: 数据收集过程可能需要数小时，请耐心等待"
    echo "📝 所有操作都会记录在logs/目录中"
}

# 运行主函数
main
