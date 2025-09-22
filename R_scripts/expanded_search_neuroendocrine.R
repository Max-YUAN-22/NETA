# R script to search for neuroendocrine tumor datasets with expanded criteria

# Install and load necessary packages
if (!requireNamespace("BiocManager", quietly = TRUE))
    install.packages("BiocManager")
if (!requireNamespace("GEOquery", quietly = TRUE))
    BiocManager::install("GEOquery")
if (!requireNamespace("stringr", quietly = TRUE))
    install.packages("stringr")

library(GEOquery)
library(stringr)

# Expanded search terms for neuroendocrine tumors
search_terms <- c(
    # Primary neuroendocrine tumor terms
    "neuroendocrine",
    "NET",
    "NEC", 
    "MINEN",
    
    # Specific neuroendocrine tumor types
    "carcinoid",
    "pheochromocytoma",
    "paraganglioma",
    "insulinoma",
    "gastrinoma",
    "glucagonoma",
    "somatostatinoma",
    "VIPoma",
    "ACTHoma",
    "adrenocortical",
    
    # Tissue-specific terms
    "pancreatic neuroendocrine",
    "lung neuroendocrine", 
    "gastrointestinal neuroendocrine",
    "small intestine neuroendocrine",
    "large intestine neuroendocrine",
    "stomach neuroendocrine",
    "liver neuroendocrine",
    "adrenal neuroendocrine",
    "thyroid neuroendocrine",
    
    # Alternative terms
    "endocrine tumor",
    "endocrine carcinoma",
    "islet cell tumor",
    "pancreatic islet",
    "neuroendocrine carcinoma",
    "neuroendocrine neoplasm",
    
    # Cell line terms
    "neuroendocrine cell line",
    "NET cell line",
    "NEC cell line"
)

# RNA-seq specific terms
rnaseq_terms <- c(
    "RNA-seq",
    "RNA sequencing", 
    "transcriptome",
    "bulk RNA",
    "RNA expression",
    "gene expression profiling",
    "high throughput sequencing",
    "next generation sequencing",
    "NGS",
    "Illumina",
    "counts",
    "raw counts",
    "HTSeq",
    "featureCounts"
)

cat("=== 扩大搜索神经内分泌肿瘤数据集 ===\n")
cat("搜索关键词:", length(search_terms), "个\n")
cat("RNA-seq关键词:", length(rnaseq_terms), "个\n\n")

# Function to search GEO with multiple terms
search_geo_expanded <- function(search_terms, rnaseq_terms, max_results = 100) {
    all_results <- list()
    
    for (i in 1:length(search_terms)) {
        term <- search_terms[i]
        cat("搜索关键词:", term, "\n")
        
        tryCatch({
            # Search for datasets containing the term
            gse_results <- getGEO(term, GSEMatrix = FALSE, destdir = "data/validation")
            
            if (length(gse_results) > 0) {
                for (j in 1:min(length(gse_results), 10)) {  # Limit to 10 results per term
                    gse_id <- names(gse_results)[j]
                    if (!gse_id %in% names(all_results)) {
                        all_results[[gse_id]] <- gse_results[[gse_id]]
                    }
                }
            }
            
            # Also search with RNA-seq terms
            for (rnaseq_term in rnaseq_terms[1:3]) {  # Limit RNA-seq terms to avoid too many requests
                combined_term <- paste(term, rnaseq_term)
                cat("  搜索组合:", combined_term, "\n")
                
                tryCatch({
                    gse_results_rnaseq <- getGEO(combined_term, GSEMatrix = FALSE, destdir = "data/validation")
                    
                    if (length(gse_results_rnaseq) > 0) {
                        for (k in 1:min(length(gse_results_rnaseq), 5)) {
                            gse_id <- names(gse_results_rnaseq)[k]
                            if (!gse_id %in% names(all_results)) {
                                all_results[[gse_id]] <- gse_results_rnaseq[[gse_id]]
                            }
                        }
                    }
                }, error = function(e) {
                    cat("    搜索失败:", e$message, "\n")
                })
                
                # Add delay to avoid overwhelming the server
                Sys.sleep(2)
            }
            
        }, error = function(e) {
            cat("搜索失败:", e$message, "\n")
        })
        
        # Add delay between searches
        Sys.sleep(3)
        
        if (length(all_results) >= max_results) {
            cat("达到最大结果数限制:", max_results, "\n")
            break
        }
    }
    
    return(all_results)
}

# Function to validate dataset with relaxed criteria
validate_dataset_relaxed <- function(gse_id, gse_object) {
    cat("验证数据集:", gse_id, "\n")
    
    gse_data <- gse_object@header
    
    # Combine relevant text for keyword search
    full_text <- paste(gse_data$title, gse_data$summary, gse_data$description, gse_data$overall_design, collapse = " ")
    
    # 1. Check if it's RNA-seq (relaxed: allow microarray but mark it)
    experiment_type <- gse_data$type
    is_rnaseq <- any(grepl("Expression profiling by high throughput sequencing", experiment_type, ignore.case = TRUE))
    is_microarray <- any(grepl("Expression profiling by array", experiment_type, ignore.case = TRUE))
    
    # 2. Check for neuroendocrine keywords (relaxed: include broader terms)
    has_net_keywords <- grepl("neuroendocrine|NET|NEC|MINEN|carcinoid|pheochromocytoma|paraganglioma|endocrine tumor|endocrine carcinoma|islet cell|pancreatic islet", full_text, ignore.case = TRUE)
    
    # 3. Check for RNA-seq keywords (relaxed: include sequencing terms)
    has_rnaseq_keywords <- grepl("RNA-seq|RNA sequencing|transcriptome|bulk RNA|high throughput sequencing|next generation sequencing|NGS|counts|HTSeq|featureCounts", full_text, ignore.case = TRUE)
    
    # 4. Check sample count
    sample_count <- length(gse_object@gsms)
    has_sufficient_samples <- sample_count >= 6
    
    # 5. Check for raw counts info (relaxed: look in supplementary files)
    has_raw_counts <- FALSE
    if (!is.null(gse_data$supplementary_file)) {
        has_raw_counts <- any(grepl("raw counts|HTSeq counts|featurecounts|count matrix|counts\\.txt|counts\\.csv", gse_data$supplementary_file, ignore.case = TRUE))
    }
    
    # 6. Check for replicates (relaxed: look for any grouping)
    has_replicates <- FALSE
    if (sample_count > 0) {
        sample_titles <- sapply(gse_object@gsms, function(x) x@header$title)
        # Look for any patterns that suggest grouping
        has_replicates <- any(grepl("rep|replicate|sample|group|treatment|control|case", sample_titles, ignore.case = TRUE))
    }
    
    # 7. Check for wild-type/control (relaxed: look for any control)
    has_wildtype <- grepl("control|wild-type|normal|baseline|untreated", full_text, ignore.case = TRUE)
    
    # 8. Check for gene intervention (relaxed: allow but mark it)
    has_intervention <- grepl("knockout|CRISPR|shRNA|siRNA|overexpression|mutant|transgenic", full_text, ignore.case = TRUE)
    
    # Overall assessment (relaxed criteria)
    is_potentially_useful <- (is_rnaseq || has_rnaseq_keywords) && has_net_keywords && has_sufficient_samples
    
    return(list(
        geo_id = gse_id,
        title = gse_data$title,
        summary = gse_data$summary,
        sample_count = sample_count,
        type = paste(experiment_type, collapse = ", "),
        is_rnaseq = is_rnaseq,
        is_microarray = is_microarray,
        has_net_keywords = has_net_keywords,
        has_sufficient_samples = has_sufficient_samples,
        has_raw_counts = has_raw_counts,
        has_replicates = has_replicates,
        has_wildtype = has_wildtype,
        has_intervention = has_intervention,
        is_potentially_useful = is_potentially_useful,
        pubmed_id = ifelse(!is.null(gse_data$pubmed_id), gse_data$pubmed_id, ""),
        submission_date = ifelse(!is.null(gse_data$submission_date), gse_data$submission_date, "")
    ))
}

# Main execution
cat("开始扩大搜索...\n")
search_results <- search_geo_expanded(search_terms, rnaseq_terms, max_results = 50)

cat("\n找到", length(search_results), "个数据集\n")

# Validate all found datasets
validated_datasets <- list()
for (gse_id in names(search_results)) {
    validation_result <- validate_dataset_relaxed(gse_id, search_results[[gse_id]])
    validated_datasets[[gse_id]] <- validation_result
}

# Filter potentially useful datasets
potentially_useful <- validated_datasets[sapply(validated_datasets, function(x) x$is_potentially_useful)]

cat("\n=== 搜索结果总结 ===\n")
cat("总数据集数:", length(validated_datasets), "\n")
cat("潜在有用数据集数:", length(potentially_useful), "\n")

if (length(potentially_useful) > 0) {
    cat("\n✅ 潜在有用的数据集:\n")
    for (id in names(potentially_useful)) {
        dataset <- potentially_useful[[id]]
        cat("  -", id, ":", dataset$title, "\n")
        cat("    样本数:", dataset$sample_count, "| RNA-seq:", dataset$is_rnaseq, "| 微阵列:", dataset$is_microarray, "\n")
        cat("    神经内分泌:", dataset$has_net_keywords, "| 原始计数:", dataset$has_raw_counts, "| 重复:", dataset$has_replicates, "\n")
        cat("    野生型:", dataset$has_wildtype, "| 基因干预:", dataset$has_intervention, "\n\n")
    }
}

# Save results
dir.create("data/expanded_search_results", recursive = TRUE, showWarnings = FALSE)
save(validated_datasets, file = "data/expanded_search_results/expanded_search_results.RData")
save(potentially_useful, file = "data/expanded_search_results/potentially_useful_datasets.RData")

cat("✅ 扩大搜索完成！结果已保存到 data/expanded_search_results/\n")
