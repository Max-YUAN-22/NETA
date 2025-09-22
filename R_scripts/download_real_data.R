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
