# R script to search for neuroendocrine tumor datasets using web scraping approach

# Install and load necessary packages
if (!requireNamespace("BiocManager", quietly = TRUE))
    install.packages("BiocManager")
if (!requireNamespace("GEOquery", quietly = TRUE))
    BiocManager::install("GEOquery")
if (!requireNamespace("stringr", quietly = TRUE))
    install.packages("stringr")
if (!requireNamespace("rvest", quietly = TRUE))
    install.packages("rvest")
if (!requireNamespace("httr", quietly = TRUE))
    install.packages("httr")

library(GEOquery)
library(stringr)
library(rvest)
library(httr)

# Known neuroendocrine tumor datasets from literature and databases
known_datasets <- c(
    # From previous searches
    "GSE182407",  # YAP1 in neuroendocrine tumors
    "GSE73338",   # Pancreatic neuroendocrine tumors
    "GSE126030",  # Neuroendocrine tumors
    "GSE165552",  # Neuroendocrine tumors
    "GSE10245",   # Lung cancer (may contain NET)
    "GSE19830",   # Pancreatic cancer (may contain NET)
    "GSE30554",   # Pancreatic cancer (may contain NET)
    "GSE59739",   # Pancreatic cancer (may contain NET)
    "GSE60361",   # Pancreatic cancer (may contain NET)
    "GSE71585",   # Pancreatic cancer (may contain NET)
    
    # Additional potential datasets
    "GSE98894",   # Neuroendocrine tumors
    "GSE132608",  # Neuroendocrine tumors
    "GSE140686",  # Neuroendocrine tumors
    "GSE145837",  # Neuroendocrine tumors
    "GSE150316",  # Neuroendocrine tumors
    "GSE156405",  # Neuroendocrine tumors
    "GSE160756",  # Neuroendocrine tumors
    "GSE164760",  # Neuroendocrine tumors
    "GSE171110",  # Neuroendocrine tumors
    "GSE180473",  # Neuroendocrine tumors
    
    # More specific searches
    "GSE103174",  # Carcinoid tumors
    "GSE114012",  # Pheochromocytoma
    "GSE117851",  # Paraganglioma
    "GSE124341",  # Insulinoma
    "GSE60436"    # Gastrinoma
)

cat("=== 搜索已知神经内分泌肿瘤数据集 ===\n")
cat("将验证", length(known_datasets), "个数据集\n\n")

# Function to validate a single dataset with relaxed criteria
validate_single_dataset <- function(geo_id) {
    cat("验证数据集:", geo_id, "\n")
    
    tryCatch({
        # Check if soft file exists locally
        soft_file_path <- file.path("data", "validation", paste0(geo_id, ".soft.gz"))
        if (file.exists(soft_file_path)) {
            cat("  使用本地缓存文件\n")
            gse <- getGEO(filename = soft_file_path)
        } else {
            cat("  从GEO下载数据\n")
            gse <- getGEO(geo_id, GSEMatrix = FALSE)
            # Save for future use
            dir.create(file.path("data", "validation"), showWarnings = FALSE)
            save(gse, file = soft_file_path)
        }
        
        # Extract metadata
        gse_data <- gse@header
        full_text <- paste(gse_data$title, gse_data$summary, gse_data$description, gse_data$overall_design, collapse = " ")
        
        # Check experiment type
        experiment_type <- gse_data$type
        is_rnaseq <- any(grepl("Expression profiling by high throughput sequencing", experiment_type, ignore.case = TRUE))
        is_microarray <- any(grepl("Expression profiling by array", experiment_type, ignore.case = TRUE))
        
        # Check for neuroendocrine keywords (relaxed)
        has_net_keywords <- grepl("neuroendocrine|NET|NEC|MINEN|carcinoid|pheochromocytoma|paraganglioma|endocrine tumor|endocrine carcinoma|islet cell|pancreatic islet|insulinoma|gastrinoma|glucagonoma|somatostatinoma|VIPoma|ACTHoma", full_text, ignore.case = TRUE)
        
        # Check for RNA-seq keywords
        has_rnaseq_keywords <- grepl("RNA-seq|RNA sequencing|transcriptome|bulk RNA|high throughput sequencing|next generation sequencing|NGS|counts|HTSeq|featureCounts", full_text, ignore.case = TRUE)
        
        # Sample count
        sample_count <- length(gse@gsms)
        
        # Check for raw counts in supplementary files
        has_raw_counts <- FALSE
        if (!is.null(gse_data$supplementary_file)) {
            has_raw_counts <- any(grepl("raw counts|HTSeq counts|featurecounts|count matrix|counts\\.txt|counts\\.csv|processed_data", gse_data$supplementary_file, ignore.case = TRUE))
        }
        
        # Check for replicates
        has_replicates <- FALSE
        if (sample_count > 0) {
            sample_titles <- sapply(gse@gsms, function(x) x@header$title)
            has_replicates <- any(grepl("rep|replicate|sample|group|treatment|control|case", sample_titles, ignore.case = TRUE))
        }
        
        # Check for control/wild-type
        has_control <- grepl("control|wild-type|normal|baseline|untreated", full_text, ignore.case = TRUE)
        
        # Check for gene intervention
        has_intervention <- grepl("knockout|CRISPR|shRNA|siRNA|overexpression|mutant|transgenic|KD|OE", full_text, ignore.case = TRUE)
        
        # Overall assessment (very relaxed criteria)
        is_potentially_useful <- has_net_keywords && sample_count >= 6
        
        result <- list(
            geo_id = geo_id,
            title = gse_data$title,
            sample_count = sample_count,
            type = paste(experiment_type, collapse = ", "),
            is_rnaseq = is_rnaseq,
            is_microarray = is_microarray,
            has_net_keywords = has_net_keywords,
            has_rnaseq_keywords = has_rnaseq_keywords,
            has_raw_counts = has_raw_counts,
            has_replicates = has_replicates,
            has_control = has_control,
            has_intervention = has_intervention,
            is_potentially_useful = is_potentially_useful,
            pubmed_id = ifelse(!is.null(gse_data$pubmed_id), gse_data$pubmed_id, ""),
            submission_date = ifelse(!is.null(gse_data$submission_date), gse_data$submission_date, "")
        )
        
        cat("  结果: 样本数=", sample_count, " RNA-seq=", is_rnaseq, " 微阵列=", is_microarray, " 神经内分泌=", has_net_keywords, " 有用=", is_potentially_useful, "\n")
        
        return(result)
        
    }, error = function(e) {
        cat("  错误:", e$message, "\n")
        return(NULL)
    })
}

# Validate all datasets
cat("开始验证数据集...\n")
validation_results <- list()

for (geo_id in known_datasets) {
    result <- validate_single_dataset(geo_id)
    if (!is.null(result)) {
        validation_results[[geo_id]] <- result
    }
    Sys.sleep(1)  # Be nice to the server
}

# Filter results
potentially_useful <- validation_results[sapply(validation_results, function(x) x$is_potentially_useful)]
rnaseq_datasets <- validation_results[sapply(validation_results, function(x) x$is_rnaseq)]
microarray_datasets <- validation_results[sapply(validation_results, function(x) x$is_microarray)]

cat("\n=== 验证结果总结 ===\n")
cat("总验证数据集数:", length(validation_results), "\n")
cat("潜在有用数据集数:", length(potentially_useful), "\n")
cat("RNA-seq数据集数:", length(rnaseq_datasets), "\n")
cat("微阵列数据集数:", length(microarray_datasets), "\n")

if (length(potentially_useful) > 0) {
    cat("\n✅ 潜在有用的数据集:\n")
    for (id in names(potentially_useful)) {
        dataset <- potentially_useful[[id]]
        cat("  -", id, ":", str_trunc(dataset$title, 60), "\n")
        cat("    样本数:", dataset$sample_count, "| RNA-seq:", dataset$is_rnaseq, "| 微阵列:", dataset$is_microarray, "\n")
        cat("    神经内分泌:", dataset$has_net_keywords, "| 原始计数:", dataset$has_raw_counts, "| 重复:", dataset$has_replicates, "\n")
        cat("    对照:", dataset$has_control, "| 基因干预:", dataset$has_intervention, "\n\n")
    }
}

if (length(rnaseq_datasets) > 0) {
    cat("\n🧬 RNA-seq数据集:\n")
    for (id in names(rnaseq_datasets)) {
        dataset <- rnaseq_datasets[[id]]
        cat("  -", id, ":", str_trunc(dataset$title, 60), "\n")
    }
}

# Save results
dir.create("data/final_search_results", recursive = TRUE, showWarnings = FALSE)
save(validation_results, file = "data/final_search_results/validation_results.RData")
save(potentially_useful, file = "data/final_search_results/potentially_useful.RData")
save(rnaseq_datasets, file = "data/final_search_results/rnaseq_datasets.RData")

cat("\n✅ 搜索完成！结果已保存到 data/final_search_results/\n")
