# R script to download and process the identified neuroendocrine tumor datasets

# Install and load necessary packages
if (!requireNamespace("BiocManager", quietly = TRUE))
    install.packages("BiocManager")
if (!requireNamespace("GEOquery", quietly = TRUE))
    BiocManager::install("GEOquery")
if (!requireNamespace("data.table", quietly = TRUE))
    install.packages("data.table")
if (!requireNamespace("stringr", quietly = TRUE))
    install.packages("stringr")

library(GEOquery)
library(data.table)
library(stringr)

# Identified useful datasets
useful_datasets <- c("GSE182407", "GSE98894", "GSE160756")

cat("=== 下载和处理神经内分泌肿瘤数据集 ===\n")
cat("将处理", length(useful_datasets), "个数据集\n\n")

# Function to download and process a single dataset
process_dataset <- function(geo_id) {
    cat("=== 处理数据集:", geo_id, "===\n")
    
    # Create output directory
    output_dir <- file.path("data", "raw", geo_id)
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
    
    tryCatch({
        # Load the GSE object
        soft_file_path <- file.path("data", "validation", paste0(geo_id, ".soft.gz"))
        if (file.exists(soft_file_path)) {
            cat("使用本地缓存文件\n")
            gse <- getGEO(filename = soft_file_path)
        } else {
            cat("从GEO下载数据\n")
            gse <- getGEO(geo_id, GSEMatrix = FALSE)
            # Save for future use
            dir.create(file.path("data", "validation"), showWarnings = FALSE)
            save(gse, file = soft_file_path)
        }
        
        # Extract metadata
        gse_data <- gse@header
        cat("数据集标题:", gse_data$title, "\n")
        cat("样本数量:", length(gse@gsms), "\n")
        
        # Check experiment type
        experiment_type <- gse_data$type
        is_rnaseq <- any(grepl("Expression profiling by high throughput sequencing", experiment_type, ignore.case = TRUE))
        cat("实验类型:", paste(experiment_type, collapse = ", "), "\n")
        cat("是否为RNA-seq:", is_rnaseq, "\n")
        
        if (is_rnaseq) {
            cat("✅ 这是RNA-seq数据集，可以进行DESeq2分析\n")
            
            # Check for supplementary files
            supplementary_files <- gse_data$supplementary_file
            if (length(supplementary_files) > 0) {
                cat("发现补充文件:", length(supplementary_files), "个\n")
                
                # Download supplementary files
                supplementary_dir <- file.path(output_dir, "supplementary")
                dir.create(supplementary_dir, recursive = TRUE, showWarnings = FALSE)
                
                for (file_url in supplementary_files) {
                    file_name <- basename(file_url)
                    dest_file <- file.path(supplementary_dir, file_name)
                    if (!file.exists(dest_file)) {
                        cat("下载补充文件:", file_name, "\n")
                        tryCatch({
                            download.file(file_url, dest_file, mode = "wb")
                            cat("✅", file_name, "下载成功\n")
                        }, error = function(e) {
                            cat("❌", file_name, "下载失败:", e$message, "\n")
                        })
                    } else {
                        cat("使用本地缓存文件:", file_name, "\n")
                    }
                }
                
                # Try to process supplementary files
                process_supplementary_files(geo_id, supplementary_dir, output_dir)
            } else {
                cat("未发现补充文件，尝试下载series matrix\n")
                tryCatch({
                    gse_matrix <- getGEO(geo_id, GSEMatrix = TRUE)
                    if (length(gse_matrix) > 0) {
                        gse_mat <- gse_matrix[[1]]
                        expr_matrix <- exprs(gse_mat)
                        pheno_data <- pData(gse_mat)
                        
                        # Save data
                        write.csv(expr_matrix, file.path(output_dir, paste0(geo_id, "_expression_matrix.csv")))
                        write.csv(pheno_data, file.path(output_dir, paste0(geo_id, "_phenotype_data.csv")))
                        
                        cat("✅ 数据保存成功\n")
                        cat("表达矩阵维度:", dim(expr_matrix), "\n")
                        cat("表型数据维度:", dim(pheno_data), "\n")
                    }
                }, error = function(e) {
                    cat("❌ 下载series matrix失败:", e$message, "\n")
                })
            }
        } else {
            cat("❌ 这不是RNA-seq数据集，跳过处理\n")
        }
        
        cat("✅", geo_id, "处理完成\n\n")
        
    }, error = function(e) {
        cat("❌", geo_id, "处理失败:", e$message, "\n\n")
    })
}

# Function to process supplementary files
process_supplementary_files <- function(geo_id, supplementary_dir, output_dir) {
    cat("=== 处理补充文件 ===\n")
    
    # Look for data files
    data_files <- list.files(supplementary_dir, pattern = "\\.(txt|gz|csv)$", full.names = TRUE)
    cat("找到数据文件:", length(data_files), "个\n")
    
    if (length(data_files) == 0) {
        cat("❌ 未找到可处理的数据文件\n")
        return(NULL)
    }
    
    # Try to process each file
    for (file_path in data_files) {
        file_name <- basename(file_path)
        cat("处理文件:", file_name, "\n")
        
        tryCatch({
            # Try different reading methods
            if (grepl("\\.gz$", file_path)) {
                # Compressed file
                data <- fread(file_path, header = TRUE, data.table = FALSE)
            } else {
                # Regular file
                data <- fread(file_path, header = TRUE, data.table = FALSE)
            }
            
            cat("文件维度:", dim(data), "\n")
            cat("列名:", colnames(data), "\n")
            
            # Check if this looks like expression data
            if (nrow(data) > 1000 && ncol(data) > 2) {
                cat("✅ 这可能是表达数据文件\n")
                
                # Save the processed file
                processed_file <- file.path(output_dir, paste0(geo_id, "_", file_name, "_processed.csv"))
                write.csv(data, processed_file)
                cat("已保存到:", processed_file, "\n")
            }
            
        }, error = function(e) {
            cat("❌ 处理文件失败:", e$message, "\n")
        })
    }
}

# Process all datasets
for (geo_id in useful_datasets) {
    process_dataset(geo_id)
}

cat("=== 所有数据集处理完成 ===\n")
cat("处理结果已保存到 data/raw/ 目录\n")
