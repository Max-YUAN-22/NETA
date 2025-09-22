#!/bin/bash

# NETA 数据查看脚本
# 无需Git LFS，直接查看本地数据

echo "🧬 NETA 数据查看工具"
echo "===================="

# 检查数据是否存在
if [ ! -d "data/raw" ]; then
    echo "❌ 数据目录不存在"
    echo "请先运行: git clone https://github.com/Max-YUAN-22/NETA.git"
    exit 1
fi

echo "📊 数据概览"
echo "----------"
echo "数据集数量: $(ls data/raw/ | wc -l)"
echo "总文件数: $(find data/raw/ -name "*.csv" | wc -l)"
echo ""

echo "📁 数据集列表"
echo "------------"
for dir in data/raw/*/; do
    if [ -d "$dir" ]; then
        dataset=$(basename "$dir")
        echo "📂 $dataset"
        
        # 显示数据集信息
        if [ -f "$dir/dataset_info.csv" ]; then
            echo "   样本数: $(tail -n +2 "$dir/dataset_info.csv" | cut -d',' -f8)"
            echo "   基因数: $(tail -n +2 "$dir/dataset_info.csv" | cut -d',' -f9)"
            echo "   组织类型: $(tail -n +2 "$dir/dataset_info.csv" | cut -d',' -f3)"
            echo "   肿瘤类型: $(tail -n +2 "$dir/dataset_info.csv" | cut -d',' -f4)"
        fi
        
        # 显示文件大小
        if [ -f "$dir/expression_matrix.csv" ]; then
            size=$(du -h "$dir/expression_matrix.csv" | cut -f1)
            echo "   表达矩阵: $size"
        fi
        
        echo ""
    fi
done

echo "🔍 查看具体数据集"
echo "----------------"
echo "选择要查看的数据集:"
echo "1) GSE73338 - 胰腺神经内分泌肿瘤"
echo "2) GSE98894 - 胃肠道神经内分泌肿瘤"
echo "3) GSE103174 - 小细胞肺癌"
echo "4) GSE117851 - 胰腺NET分子亚型"
echo "5) GSE156405 - 胰腺NET进展和转移"
echo "6) GSE11969 - 肺神经内分泌肿瘤"
echo "7) GSE60436 - SCLC细胞系"
echo "8) GSE126030 - 肺神经内分泌癌亚型"
echo "9) 查看数据摘要"
echo "0) 退出"

read -p "请输入选择 (0-9): " choice

case $choice in
    1) dataset="GSE73338" ;;
    2) dataset="GSE98894" ;;
    3) dataset="GSE103174" ;;
    4) dataset="GSE117851" ;;
    5) dataset="GSE156405" ;;
    6) dataset="GSE11969" ;;
    7) dataset="GSE60436" ;;
    8) dataset="GSE126030" ;;
    9) 
        echo "📊 数据摘要"
        echo "----------"
        if [ -f "data/download_summary.csv" ]; then
            head -5 data/download_summary.csv
        fi
        exit 0
        ;;
    0) exit 0 ;;
    *) echo "❌ 无效选择"; exit 1 ;;
esac

echo ""
echo "📂 查看数据集: $dataset"
echo "========================"

# 显示数据集信息
if [ -f "data/raw/$dataset/dataset_info.csv" ]; then
    echo "📋 数据集信息:"
    cat "data/raw/$dataset/dataset_info.csv"
    echo ""
fi

# 显示表达矩阵前几行
if [ -f "data/raw/$dataset/expression_matrix.csv" ]; then
    echo "🧬 表达矩阵 (前5行):"
    head -5 "data/raw/$dataset/expression_matrix.csv"
    echo ""
    echo "📊 表达矩阵维度:"
    echo "   行数 (基因数): $(tail -n +2 "data/raw/$dataset/expression_matrix.csv" | wc -l)"
    echo "   列数 (样本数): $(head -1 "data/raw/$dataset/expression_matrix.csv" | tr ',' '\n' | wc -l)"
    echo ""
fi

# 显示表型数据前几行
if [ -f "data/raw/$dataset/phenotype_data.csv" ]; then
    echo "👥 表型数据 (前5行):"
    head -5 "data/raw/$dataset/phenotype_data.csv"
    echo ""
fi

echo "💡 提示:"
echo "  - 完整数据可在GitHub Pages查看: https://max-yuan-22.github.io/NETA/"
echo "  - 在线查看无需Git LFS"
echo "  - 如需下载完整数据，使用: git lfs pull"
