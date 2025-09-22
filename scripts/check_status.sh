#!/bin/bash
# NETA数据收集状态检查脚本

echo "🧬 NETA数据收集状态检查"
echo "========================"

# 检查磁盘空间
echo "💾 磁盘空间检查:"
df -h . | head -2
echo ""

# 检查网络连接
echo "🌐 网络连接检查:"
if ping -c 1 ncbi.nlm.nih.gov &> /dev/null; then
    echo "✅ NCBI连接正常"
else
    echo "❌ NCBI连接异常"
fi

if ping -c 1 ebi.ac.uk &> /dev/null; then
    echo "✅ EBI连接正常"
else
    echo "❌ EBI连接异常"
fi
echo ""

# 检查R环境
echo "🔧 R环境检查:"
if command -v R &> /dev/null; then
    echo "✅ R已安装: $(R --version | head -1)"
else
    echo "❌ R未安装"
fi

if command -v Rscript &> /dev/null; then
    echo "✅ Rscript可用"
else
    echo "❌ Rscript不可用"
fi
echo ""

# 检查数据目录
echo "📁 数据目录检查:"
if [ -d "data" ]; then
    echo "✅ data目录存在"
    echo "   原始数据: $(find data/raw -name "*.rds" 2>/dev/null | wc -l) 个文件"
    echo "   处理后数据: $(find data/processed -name "*.rds" 2>/dev/null | wc -l) 个文件"
else
    echo "❌ data目录不存在"
fi
echo ""

# 检查脚本文件
echo "📜 脚本文件检查:"
scripts=("R_scripts/real_datasets.R" "R_scripts/data_processing.R" "scripts/prepare_data_collection.sh")
for script in "${scripts[@]}"; do
    if [ -f "$script" ]; then
        echo "✅ $script 存在"
    else
        echo "❌ $script 不存在"
    fi
done
echo ""

# 检查日志文件
echo "📝 日志文件检查:"
if [ -d "logs" ]; then
    echo "✅ logs目录存在"
    echo "   日志文件数量: $(find logs -name "*.log" 2>/dev/null | wc -l)"
else
    echo "❌ logs目录不存在"
fi
echo ""

# 检查R包
echo "📦 R包检查:"
Rscript -e "
required_packages <- c('GEOquery', 'dplyr', 'stringr')
missing_packages <- c()

for (pkg in required_packages) {
    if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
        missing_packages <- c(missing_packages, pkg)
    }
}

if (length(missing_packages) == 0) {
    cat('✅ 所有必需的R包已安装\n')
} else {
    cat('❌ 缺少R包:', paste(missing_packages, collapse = ', '), '\n')
}
"
echo ""

# 检查数据收集准备状态
echo "🚀 数据收集准备状态:"
if [ -f "scripts/prepare_data_collection.sh" ]; then
    echo "✅ 数据收集准备脚本存在"
    if [ -x "scripts/prepare_data_collection.sh" ]; then
        echo "✅ 脚本可执行"
    else
        echo "❌ 脚本不可执行，运行: chmod +x scripts/prepare_data_collection.sh"
    fi
else
    echo "❌ 数据收集准备脚本不存在"
fi
echo ""

# 检查2TB硬盘连接
echo "💽 2TB硬盘检查:"
available_space=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "$available_space" -gt 1500 ]; then
    echo "✅ 磁盘空间充足 (${available_space}GB)"
    echo "✅ 可以开始数据收集"
else
    echo "❌ 磁盘空间不足 (${available_space}GB)"
    echo "❌ 请连接2TB硬盘"
fi
echo ""

# 总结
echo "📋 检查总结:"
echo "============="

# 计算检查项目
total_checks=8
passed_checks=0

# 磁盘空间检查
if [ "$available_space" -gt 1500 ]; then
    ((passed_checks++))
fi

# 网络连接检查
if ping -c 1 ncbi.nlm.nih.gov &> /dev/null; then
    ((passed_checks++))
fi

# R环境检查
if command -v R &> /dev/null; then
    ((passed_checks++))
fi

# 数据目录检查
if [ -d "data" ]; then
    ((passed_checks++))
fi

# 脚本文件检查
if [ -f "R_scripts/real_datasets.R" ] && [ -f "R_scripts/data_processing.R" ]; then
    ((passed_checks++))
fi

# 日志目录检查
if [ -d "logs" ]; then
    ((passed_checks++))
fi

# 准备脚本检查
if [ -f "scripts/prepare_data_collection.sh" ] && [ -x "scripts/prepare_data_collection.sh" ]; then
    ((passed_checks++))
fi

# R包检查（简化）
if Rscript -e "require('GEOquery', quietly = TRUE)" &> /dev/null; then
    ((passed_checks++))
fi

echo "通过检查: $passed_checks/$total_checks"

if [ $passed_checks -eq $total_checks ]; then
    echo "🎉 所有检查通过！可以开始数据收集"
    echo ""
    echo "📋 下一步操作:"
    echo "1. 运行数据收集准备: ./scripts/prepare_data_collection.sh"
    echo "2. 开始数据收集: ./scripts/start_data_collection.sh"
    echo "3. 验证数据质量: ./scripts/validate_data.sh"
else
    echo "⚠️  部分检查未通过，请解决上述问题后重新检查"
fi

echo ""
echo "检查完成时间: $(date)"
