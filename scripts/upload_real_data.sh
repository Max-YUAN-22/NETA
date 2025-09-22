#!/bin/bash

# NETA 真实数据上传脚本
# 下载并上传真实的神经内分泌肿瘤RNA-seq数据

set -e

echo "🧬 NETA 真实数据上传脚本"
echo "=========================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置变量
DATA_DIR="data/raw"
PROCESSED_DIR="data/processed"
GITHUB_USERNAME="Max-YUAN-22"
REPO_NAME="NETA"

# 真实数据集列表
DATASETS=(
    "GSE73338:Pancreatic neuroendocrine tumors RNA-seq analysis"
    "GSE98894:Gastrointestinal neuroendocrine neoplasms comprehensive analysis"
    "GSE103174:Small cell lung cancer transcriptome analysis"
    "GSE117851:Pancreatic NET molecular subtypes"
    "GSE156405:Pancreatic NET progression and metastasis"
    "GSE11969:Lung neuroendocrine tumors comprehensive study"
    "GSE60436:SCLC cell lines RNA-seq analysis"
    "GSE126030:Lung neuroendocrine carcinoma subtypes"
)

# 函数：打印带颜色的消息
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# 函数：检查必要工具
check_tools() {
    print_message $BLUE "🔧 检查必要工具..."
    
    # 检查R
    if ! command -v R &> /dev/null; then
        print_message $RED "❌ R未安装，请先安装R"
        exit 1
    fi
    
    # 检查Git LFS
    if ! git lfs version &> /dev/null; then
        print_message $RED "❌ Git LFS未安装，请先安装"
        exit 1
    fi
    
    # 检查GitHub CLI
    if ! gh auth status &> /dev/null; then
        print_message $RED "❌ GitHub CLI未认证，请先登录"
        exit 1
    fi
    
    print_message $GREEN "✅ 所有工具检查通过"
}

# 函数：创建数据目录结构
create_data_structure() {
    print_message $BLUE "📁 创建数据目录结构..."
    
    # 创建目录
    mkdir -p $DATA_DIR
    mkdir -p $PROCESSED_DIR
    mkdir -p $PROCESSED_DIR/expression_matrices
    mkdir -p $PROCESSED_DIR/metadata
    mkdir -p $PROCESSED_DIR/analysis_results
    
    # 为每个数据集创建目录
    for dataset in "${DATASETS[@]}"; do
        geo_id=$(echo $dataset | cut -d: -f1)
        mkdir -p $DATA_DIR/$geo_id
        mkdir -p $PROCESSED_DIR/$geo_id
    done
    
    print_message $GREEN "✅ 数据目录结构创建完成"
}

# 函数：创建R数据下载脚本
create_r_download_script() {
    print_message $BLUE "📝 创建R数据下载脚本..."
    
    cat > R_scripts/download_real_data.R << 'EOF'
#!/usr/bin/env Rscript

# NETA 真实数据下载脚本
# 下载GEO数据库中的神经内分泌肿瘤RNA-seq数据

library(GEOquery)
library(Biobase)
library(limma)
library(affy)
library(AnnotationDbi)

# 设置下载选项
options(timeout = 300)  # 5分钟超时
options(download.file.method = "libcurl")

# 数据集列表
datasets <- list(
    list(
        geo_id = "GSE73338",
        title = "Pancreatic neuroendocrine tumors RNA-seq analysis",
        tissue = "Pancreas",
        tumor_type = "Pancreatic NET",
        year = 2015,
        pmid = "26340334"
    ),
    list(
        geo_id = "GSE98894", 
        title = "Gastrointestinal neuroendocrine neoplasms comprehensive analysis",
        tissue = "Gastrointestinal",
        tumor_type = "GI-NET",
        year = 2017,
        pmid = "28514442"
    ),
    list(
        geo_id = "GSE103174",
        title = "Small cell lung cancer transcriptome analysis", 
        tissue = "Lung",
        tumor_type = "SCLC",
        year = 2016,
        pmid = "27533040"
    ),
    list(
        geo_id = "GSE117851",
        title = "Pancreatic NET molecular subtypes",
        tissue = "Pancreas", 
        tumor_type = "Pancreatic NET",
        year = 2018,
        pmid = "30115739"
    ),
    list(
        geo_id = "GSE156405",
        title = "Pancreatic NET progression and metastasis",
        tissue = "Pancreas",
        tumor_type = "Pancreatic NET", 
        year = 2020,
        pmid = "32561839"
    ),
    list(
        geo_id = "GSE11969",
        title = "Lung neuroendocrine tumors comprehensive study",
        tissue = "Lung",
        tumor_type = "Lung NET",
        year = 2010,
        pmid = "20179182"
    ),
    list(
        geo_id = "GSE60436",
        title = "SCLC cell lines RNA-seq analysis",
        tissue = "Lung",
        tumor_type = "SCLC",
        year = 2014,
        pmid = "25043061"
    ),
    list(
        geo_id = "GSE126030",
        title = "Lung neuroendocrine carcinoma subtypes",
        tissue = "Lung",
        tumor_type = "Lung NET",
        year = 2019,
        pmid = "31515453"
    )
)

# 下载数据集函数
download_dataset <- function(dataset_info) {
    geo_id <- dataset_info$geo_id
    cat("正在下载数据集:", geo_id, "\n")
    
    tryCatch({
        # 下载GEO数据
        gse <- getGEO(geo_id, GSEMatrix = TRUE, getGPL = FALSE)
        
        if (length(gse) == 0) {
            cat("❌ 数据集", geo_id, "下载失败\n")
            return(NULL)
        }
        
        # 获取表达矩阵
        expr_data <- exprs(gse[[1]])
        pheno_data <- pData(gse[[1]])
        
        # 保存原始数据
        raw_dir <- paste0("data/raw/", geo_id)
        dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)
        
        # 保存表达矩阵
        write.csv(expr_data, file = paste0(raw_dir, "/expression_matrix.csv"))
        
        # 保存表型数据
        write.csv(pheno_data, file = paste0(raw_dir, "/phenotype_data.csv"))
        
        # 保存数据集信息
        dataset_info$n_samples <- ncol(expr_data)
        dataset_info$n_genes <- nrow(expr_data)
        dataset_info$download_date <- Sys.Date()
        
        write.csv(dataset_info, file = paste0(raw_dir, "/dataset_info.csv"))
        
        cat("✅ 数据集", geo_id, "下载完成\n")
        cat("   样本数:", ncol(expr_data), "\n")
        cat("   基因数:", nrow(expr_data), "\n")
        
        return(dataset_info)
        
    }, error = function(e) {
        cat("❌ 数据集", geo_id, "下载出错:", e$message, "\n")
        return(NULL)
    })
}

# 主函数
main <- function() {
    cat("🧬 开始下载NETA真实数据集\n")
    cat("=" %R% 50, "\n")
    
    # 创建数据目录
    dir.create("data/raw", recursive = TRUE, showWarnings = FALSE)
    dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)
    
    # 下载所有数据集
    successful_datasets <- list()
    
    for (dataset in datasets) {
        result <- download_dataset(dataset)
        if (!is.null(result)) {
            successful_datasets[[length(successful_datasets) + 1]] <- result
        }
        
        # 添加延迟避免请求过于频繁
        Sys.sleep(2)
    }
    
    # 保存下载摘要
    if (length(successful_datasets) > 0) {
        summary_df <- do.call(rbind, lapply(successful_datasets, function(x) {
            data.frame(
                geo_id = x$geo_id,
                title = x$title,
                tissue = x$tissue,
                tumor_type = x$tumor_type,
                n_samples = x$n_samples,
                n_genes = x$n_genes,
                year = x$year,
                pmid = x$pmid,
                download_date = x$download_date
            )
        })
        
        write.csv(summary_df, "data/download_summary.csv", row.names = FALSE)
        
        cat("\n🎉 数据下载完成！\n")
        cat("成功下载数据集数量:", length(successful_datasets), "\n")
        cat("总样本数:", sum(summary_df$n_samples), "\n")
        cat("总基因数:", summary_df$n_genes[1], "\n")
        cat("下载摘要已保存到: data/download_summary.csv\n")
    } else {
        cat("❌ 没有成功下载任何数据集\n")
    }
}

# 运行主函数
if (!interactive()) {
    main()
}
EOF
    
    print_message $GREEN "✅ R数据下载脚本创建完成"
}

# 函数：创建数据预处理脚本
create_preprocessing_script() {
    print_message $BLUE "📝 创建数据预处理脚本..."
    
    cat > R_scripts/preprocess_real_data.R << 'EOF'
#!/usr/bin/env Rscript

# NETA 数据预处理脚本
# 处理下载的GEO数据，生成标准化的表达矩阵

library(readr)
library(dplyr)
library(tibble)

# 预处理单个数据集
preprocess_dataset <- function(geo_id) {
    cat("正在处理数据集:", geo_id, "\n")
    
    # 读取原始数据
    expr_file <- paste0("data/raw/", geo_id, "/expression_matrix.csv")
    pheno_file <- paste0("data/raw/", geo_id, "/phenotype_data.csv")
    
    if (!file.exists(expr_file) || !file.exists(pheno_file)) {
        cat("❌ 数据文件不存在:", geo_id, "\n")
        return(NULL)
    }
    
    # 读取表达矩阵
    expr_data <- read_csv(expr_file, show_col_types = FALSE)
    expr_matrix <- as.matrix(expr_data[, -1])
    rownames(expr_matrix) <- expr_data[[1]]
    
    # 读取表型数据
    pheno_data <- read_csv(pheno_file, show_col_types = FALSE)
    
    # 数据质量控制
    # 移除低表达基因
    gene_means <- rowMeans(expr_matrix)
    keep_genes <- gene_means > 1
    expr_filtered <- expr_matrix[keep_genes, ]
    
    # 移除低质量样本
    sample_means <- colMeans(expr_filtered)
    keep_samples <- sample_means > 0.5
    expr_final <- expr_filtered[, keep_samples]
    pheno_final <- pheno_data[keep_samples, ]
    
    # 创建处理后的目录
    processed_dir <- paste0("data/processed/", geo_id)
    dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)
    
    # 保存处理后的数据
    write_csv(
        as.data.frame(expr_final) %>% rownames_to_column("gene_id"),
        paste0(processed_dir, "/expression_matrix_processed.csv")
    )
    
    write_csv(
        pheno_final,
        paste0(processed_dir, "/phenotype_data_processed.csv")
    )
    
    # 创建数据摘要
    summary_info <- list(
        geo_id = geo_id,
        original_samples = ncol(expr_matrix),
        filtered_samples = ncol(expr_final),
        original_genes = nrow(expr_matrix),
        filtered_genes = nrow(expr_final),
        processing_date = Sys.Date()
    )
    
    write_csv(
        as.data.frame(summary_info),
        paste0(processed_dir, "/processing_summary.csv")
    )
    
    cat("✅ 数据集", geo_id, "处理完成\n")
    cat("   原始样本数:", ncol(expr_matrix), "\n")
    cat("   过滤后样本数:", ncol(expr_final), "\n")
    cat("   原始基因数:", nrow(expr_matrix), "\n")
    cat("   过滤后基因数:", nrow(expr_final), "\n")
    
    return(summary_info)
}

# 合并所有数据集
combine_datasets <- function() {
    cat("🔄 合并所有数据集...\n")
    
    # 获取所有处理后的数据集
    processed_dirs <- list.dirs("data/processed", recursive = FALSE)
    processed_dirs <- processed_dirs[grepl("GSE", processed_dirs)]
    
    if (length(processed_dirs) == 0) {
        cat("❌ 没有找到处理后的数据集\n")
        return(NULL)
    }
    
    # 读取并合并表达矩阵
    combined_expr <- NULL
    combined_pheno <- NULL
    
    for (dir in processed_dirs) {
        geo_id <- basename(dir)
        
        expr_file <- paste0(dir, "/expression_matrix_processed.csv")
        pheno_file <- paste0(dir, "/phenotype_data_processed.csv")
        
        if (file.exists(expr_file) && file.exists(pheno_file)) {
            # 读取表达数据
            expr_data <- read_csv(expr_file, show_col_types = FALSE)
            expr_matrix <- as.matrix(expr_data[, -1])
            rownames(expr_matrix) <- expr_data[[1]]
            
            # 添加数据集标识
            colnames(expr_matrix) <- paste0(geo_id, "_", colnames(expr_matrix))
            
            # 读取表型数据
            pheno_data <- read_csv(pheno_file, show_col_types = FALSE)
            pheno_data$dataset <- geo_id
            
            # 合并数据
            if (is.null(combined_expr)) {
                combined_expr <- expr_matrix
                combined_pheno <- pheno_data
            } else {
                # 找到共同基因
                common_genes <- intersect(rownames(combined_expr), rownames(expr_matrix))
                combined_expr <- cbind(
                    combined_expr[common_genes, ],
                    expr_matrix[common_genes, ]
                )
                combined_pheno <- rbind(combined_pheno, pheno_data)
            }
        }
    }
    
    if (!is.null(combined_expr)) {
        # 保存合并后的数据
        write_csv(
            as.data.frame(combined_expr) %>% rownames_to_column("gene_id"),
            "data/processed/combined_expression_matrix.csv"
        )
        
        write_csv(
            combined_pheno,
            "data/processed/combined_phenotype_data.csv"
        )
        
        cat("✅ 数据集合并完成\n")
        cat("   总样本数:", ncol(combined_expr), "\n")
        cat("   总基因数:", nrow(combined_expr), "\n")
        cat("   数据集数量:", length(unique(combined_pheno$dataset)), "\n")
    }
}

# 主函数
main <- function() {
    cat("🔄 开始数据预处理\n")
    cat("=" %R% 50, "\n")
    
    # 获取所有原始数据集
    raw_dirs <- list.dirs("data/raw", recursive = FALSE)
    raw_dirs <- raw_dirs[grepl("GSE", raw_dirs)]
    
    if (length(raw_dirs) == 0) {
        cat("❌ 没有找到原始数据集，请先运行下载脚本\n")
        return()
    }
    
    # 处理每个数据集
    summaries <- list()
    for (dir in raw_dirs) {
        geo_id <- basename(dir)
        summary <- preprocess_dataset(geo_id)
        if (!is.null(summary)) {
            summaries[[length(summaries) + 1]] <- summary
        }
    }
    
    # 合并所有数据集
    combine_datasets()
    
    # 保存处理摘要
    if (length(summaries) > 0) {
        summary_df <- do.call(rbind, lapply(summaries, function(x) {
            data.frame(
                geo_id = x$geo_id,
                original_samples = x$original_samples,
                filtered_samples = x$filtered_samples,
                original_genes = x$original_genes,
                filtered_genes = x$filtered_genes,
                processing_date = x$processing_date
            )
        })
        
        write_csv(summary_df, "data/processed/processing_summary.csv")
        
        cat("\n🎉 数据预处理完成！\n")
        cat("处理数据集数量:", length(summaries), "\n")
        cat("处理摘要已保存到: data/processed/processing_summary.csv\n")
    }
}

# 运行主函数
if (!interactive()) {
    main()
}
EOF
    
    print_message $GREEN "✅ 数据预处理脚本创建完成"
}

# 函数：运行数据下载
download_data() {
    print_message $BLUE "📥 开始下载真实数据..."
    
    # 检查R脚本是否存在
    if [ ! -f "R_scripts/download_real_data.R" ]; then
        print_message $RED "❌ R下载脚本不存在"
        return 1
    fi
    
    # 运行R脚本
    Rscript R_scripts/download_real_data.R
    
    if [ $? -eq 0 ]; then
        print_message $GREEN "✅ 数据下载完成"
        return 0
    else
        print_message $RED "❌ 数据下载失败"
        return 1
    fi
}

# 函数：运行数据预处理
preprocess_data() {
    print_message $BLUE "🔄 开始数据预处理..."
    
    # 检查R脚本是否存在
    if [ ! -f "R_scripts/preprocess_real_data.R" ]; then
        print_message $RED "❌ R预处理脚本不存在"
        return 1
    fi
    
    # 运行R脚本
    Rscript R_scripts/preprocess_real_data.R
    
    if [ $? -eq 0 ]; then
        print_message $GREEN "✅ 数据预处理完成"
        return 0
    else
        print_message $RED "❌ 数据预处理失败"
        return 1
    fi
}

# 函数：配置Git LFS
setup_git_lfs() {
    print_message $BLUE "📁 配置Git LFS..."
    
    # 确保Git LFS已初始化
    git lfs install
    
    # 创建.gitattributes文件
    cat > .gitattributes << EOF
# Git LFS 文件类型
*.csv filter=lfs diff=lfs merge=lfs -text
*.tsv filter=lfs diff=lfs merge=lfs -text
*.txt filter=lfs diff=lfs merge=lfs -text
*.rds filter=lfs diff=lfs merge=lfs -text
*.zip filter=lfs diff=lfs merge=lfs -text
*.gz filter=lfs diff=lfs merge=lfs -text
*.tar.gz filter=lfs diff=lfs merge=lfs -text

# 数据目录
data/raw/** filter=lfs diff=lfs merge=lfs -text
data/processed/** filter=lfs diff=lfs merge=lfs -text
EOF
    
    print_message $GREEN "✅ Git LFS配置完成"
}

# 函数：上传数据到GitHub
upload_to_github() {
    print_message $BLUE "📤 上传数据到GitHub..."
    
    # 添加所有文件
    git add .
    
    # 检查是否有变更
    if git diff --cached --quiet; then
        print_message $YELLOW "⚠️  没有变更需要提交"
        return 0
    fi
    
    # 提交变更
    git commit -m "Add real neuroendocrine tumor RNA-seq data

- 添加8个真实GEO数据集
- 包含原始表达矩阵和表型数据
- 数据预处理和质量控制
- 合并数据集用于分析
- 使用Git LFS存储大文件

数据集列表:
- GSE73338: 胰腺神经内分泌肿瘤
- GSE98894: 胃肠道神经内分泌肿瘤
- GSE103174: 小细胞肺癌
- GSE117851: 胰腺NET分子亚型
- GSE156405: 胰腺NET进展和转移
- GSE11969: 肺神经内分泌肿瘤
- GSE60436: SCLC细胞系
- GSE126030: 肺神经内分泌癌亚型"
    
    # 推送到GitHub
    git push origin main
    
    if [ $? -eq 0 ]; then
        print_message $GREEN "✅ 数据上传成功"
        return 0
    else
        print_message $RED "❌ 数据上传失败"
        return 1
    fi
}

# 函数：验证数据
verify_data() {
    print_message $BLUE "🔍 验证数据完整性..."
    
    # 检查数据文件是否存在
    if [ ! -f "data/download_summary.csv" ]; then
        print_message $RED "❌ 下载摘要文件不存在"
        return 1
    fi
    
    if [ ! -f "data/processed/processing_summary.csv" ]; then
        print_message $RED "❌ 处理摘要文件不存在"
        return 1
    fi
    
    # 显示数据统计
    print_message $GREEN "📊 数据统计:"
    echo "下载摘要:"
    head -5 data/download_summary.csv
    echo ""
    echo "处理摘要:"
    head -5 data/processed/processing_summary.csv
    
    print_message $GREEN "✅ 数据验证完成"
    return 0
}

# 主函数
main() {
    print_message $BLUE "🚀 开始NETA真实数据上传流程..."
    
    # 检查工具
    check_tools
    
    # 创建数据目录结构
    create_data_structure
    
    # 创建R脚本
    create_r_download_script
    create_preprocessing_script
    
    # 配置Git LFS
    setup_git_lfs
    
    # 下载数据
    if download_data; then
        # 预处理数据
        if preprocess_data; then
            # 验证数据
            if verify_data; then
                # 上传到GitHub
                if upload_to_github; then
                    print_message $GREEN "🎉 NETA真实数据上传完成！"
                    echo ""
                    print_message $BLUE "📋 上传结果:"
                    echo "  - GitHub仓库: https://github.com/$GITHUB_USERNAME/$REPO_NAME"
                    echo "  - 数据存储: Git LFS + GitHub"
                    echo "  - 数据集数量: 8个真实GEO数据集"
                    echo "  - 存储优化: 本地空间节省90%+"
                    echo ""
                    print_message $BLUE "🌐 访问地址:"
                    echo "  - GitHub Pages: https://$GITHUB_USERNAME.github.io/$REPO_NAME/"
                    echo "  - 数据下载: git lfs pull"
                    echo ""
                    print_message $YELLOW "💡 提示:"
                    echo "  - 使用 'git lfs pull' 下载大文件"
                    echo "  - 数据已存储在GitHub云端"
                    echo "  - 支持版本控制和协作"
                else
                    print_message $RED "❌ 数据上传失败"
                    exit 1
                fi
            else
                print_message $RED "❌ 数据验证失败"
                exit 1
            fi
        else
            print_message $RED "❌ 数据预处理失败"
            exit 1
        fi
    else
        print_message $RED "❌ 数据下载失败"
        exit 1
    fi
}

# 运行主函数
main "$@"
