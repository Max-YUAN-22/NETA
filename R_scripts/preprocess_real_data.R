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
