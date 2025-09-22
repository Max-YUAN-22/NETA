# NETA Data Processing Pipeline
# 神经内分泌肿瘤Bulk-RNA-seq数据处理流程

# 加载必要的R包
library(limma)
library(edgeR)
library(DESeq2)
library(SummarizedExperiment)
library(AnnotationDbi)
library(org.Hs.eg.db)
library(GEOquery)
library(TCGAbiolinks)
library(dplyr)
library(tidyr)
library(ggplot2)
library(pheatmap)
library(VennDiagram)

# 设置工作目录和参数
setwd(".")
options(stringsAsFactors = FALSE)

# 1. 数据下载和预处理函数
download_geo_data <- function(geo_id, destdir = "data/raw") {
  # 下载GEO数据
  if (!dir.exists(destdir)) {
    dir.create(destdir, recursive = TRUE)
  }
  
  # 下载数据
  gse <- getGEO(geo_id, destdir = destdir, GSEMatrix = TRUE)
  
  # 提取表达矩阵和表型数据
  expr_matrix <- exprs(gse[[1]])
  pheno_data <- pData(gse[[1]])
  
  return(list(expression = expr_matrix, metadata = pheno_data))
}

# 2. 数据质量控制
quality_control <- function(expr_matrix, metadata) {
  # 计算QC指标
  qc_metrics <- data.frame(
    Sample_ID = colnames(expr_matrix),
    Total_Reads = colSums(expr_matrix),
    Detected_Genes = colSums(expr_matrix > 0),
    Median_Expression = apply(expr_matrix, 2, median),
    stringsAsFactors = FALSE
  )
  
  # 合并表型数据
  qc_metrics <- merge(qc_metrics, metadata, by.x = "Sample_ID", by.y = "geo_accession", all.x = TRUE)
  
  # 过滤低质量样本
  filtered_samples <- qc_metrics[
    qc_metrics$Detected_Genes > 5000 & 
    qc_metrics$Total_Reads > 1000000, 
  ]
  
  # 过滤低表达基因
  filtered_expr <- expr_matrix[, filtered_samples$Sample_ID]
  gene_counts <- rowSums(filtered_expr > 0)
  filtered_expr <- filtered_expr[gene_counts > ncol(filtered_expr) * 0.1, ]
  
  return(list(expression = filtered_expr, metadata = filtered_samples))
}

# 3. 数据标准化
normalize_data <- function(expr_matrix, method = "quantile") {
  if (method == "quantile") {
    # Quantile normalization
    normalized_expr <- normalizeQuantiles(expr_matrix)
  } else if (method == "log2") {
    # Log2 transformation
    normalized_expr <- log2(expr_matrix + 1)
  } else if (method == "vst") {
    # Variance stabilizing transformation
    normalized_expr <- vst(expr_matrix)
  }
  
  return(normalized_expr)
}

# 4. 批次效应校正
batch_correction <- function(expr_matrix, metadata, batch_var = "batch") {
  # 使用ComBat进行批次校正
  library(sva)
  
  if (batch_var %in% colnames(metadata)) {
    batch <- metadata[[batch_var]]
    corrected_expr <- ComBat(dat = expr_matrix, batch = batch)
  } else {
    corrected_expr <- expr_matrix
  }
  
  return(corrected_expr)
}

# 5. 差异表达分析
differential_expression <- function(expr_matrix, metadata, group_var, 
                                   method = "limma", 
                                   fc_threshold = 1.5, 
                                   pval_threshold = 0.05) {
  
  # 创建设计矩阵
  design <- model.matrix(~ 0 + metadata[[group_var]])
  colnames(design) <- levels(factor(metadata[[group_var]]))
  
  # 使用limma进行差异表达分析
  if (method == "limma") {
    fit <- lmFit(expr_matrix, design)
    
    # 定义对比
    contrasts <- makeContrasts(
      contrasts = paste(colnames(design)[2], "-", colnames(design)[1]),
      levels = design
    )
    
    fit2 <- contrasts.fit(fit, contrasts)
    fit2 <- eBayes(fit2)
    
    # 提取结果
    results <- topTable(fit2, number = Inf, adjust.method = "BH")
    
  } else if (method == "edgeR") {
    # 使用edgeR进行差异表达分析
    dge <- DGEList(counts = expr_matrix)
    dge <- calcNormFactors(dge)
    
    design_edgeR <- model.matrix(~ metadata[[group_var]])
    dge <- estimateDisp(dge, design_edgeR)
    
    fit_edgeR <- glmQLFit(dge, design_edgeR)
    qlf <- glmQLFTest(fit_edgeR)
    
    results <- topTags(qlf, n = Inf)$table
  }
  
  # 过滤显著差异表达基因
  significant_genes <- results[
    abs(results$logFC) >= log2(fc_threshold) & 
    results$P.Value <= pval_threshold, 
  ]
  
  return(list(all_results = results, significant = significant_genes))
}

# 6. 基因集富集分析
gene_set_enrichment <- function(de_results, gene_sets = "GO", 
                               organism = "org.Hs.eg.db") {
  
  library(clusterProfiler)
  library(org.Hs.eg.db)
  
  # 准备基因列表
  gene_list <- de_results$logFC
  names(gene_list) <- rownames(de_results)
  gene_list <- sort(gene_list, decreasing = TRUE)
  
  # GO富集分析
  if (gene_sets == "GO") {
    ego <- gseGO(geneList = gene_list,
                 OrgDb = org.Hs.eg.db,
                 ont = "ALL",
                 keyType = "SYMBOL",
                 minGSSize = 10,
                 maxGSSize = 500,
                 pvalueCutoff = 0.05,
                 verbose = FALSE)
    
    return(ego)
  }
  
  # KEGG富集分析
  if (gene_sets == "KEGG") {
    kegg <- gseKEGG(geneList = gene_list,
                    organism = "hsa",
                    minGSSize = 10,
                    maxGSSize = 500,
                    pvalueCutoff = 0.05,
                    verbose = FALSE)
    
    return(kegg)
  }
}

# 7. 生存分析
survival_analysis <- function(expr_matrix, metadata, 
                              survival_time, survival_status,
                              gene_name, cutoff_method = "median") {
  
  library(survival)
  library(survminer)
  
  # 提取目标基因表达
  gene_expr <- expr_matrix[gene_name, ]
  
  # 根据cutoff分组
  if (cutoff_method == "median") {
    cutoff <- median(gene_expr, na.rm = TRUE)
  } else if (cutoff_method == "quartile") {
    cutoff <- quantile(gene_expr, 0.75, na.rm = TRUE)
  }
  
  # 创建高低表达组
  high_expr <- gene_expr >= cutoff
  low_expr <- gene_expr < cutoff
  
  # 创建生存数据
  surv_data <- data.frame(
    time = metadata[[survival_time]],
    status = metadata[[survival_status]],
    group = ifelse(high_expr, "High", "Low"),
    stringsAsFactors = FALSE
  )
  
  # 移除缺失值
  surv_data <- surv_data[complete.cases(surv_data), ]
  
  # 进行生存分析
  surv_obj <- Surv(surv_data$time, surv_data$status)
  surv_fit <- survfit(surv_obj ~ surv_data$group)
  
  # Cox回归分析
  cox_fit <- coxph(surv_obj ~ surv_data$group)
  
  return(list(surv_fit = surv_fit, cox_fit = cox_fit, surv_data = surv_data))
}

# 8. 主处理流程
process_neta_data <- function(geo_ids, output_dir = "data/processed") {
  
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }
  
  # 存储所有数据
  all_expr <- list()
  all_metadata <- list()
  
  # 处理每个GEO数据集
  for (geo_id in geo_ids) {
    cat("Processing", geo_id, "...\n")
    
    # 下载数据
    raw_data <- download_geo_data(geo_id)
    
    # 质量控制
    qc_data <- quality_control(raw_data$expression, raw_data$metadata)
    
    # 标准化
    normalized_expr <- normalize_data(qc_data$expression)
    
    # 存储数据
    all_expr[[geo_id]] <- normalized_expr
    all_metadata[[geo_id]] <- qc_data$metadata
  }
  
  # 合并所有数据集
  common_genes <- Reduce(intersect, lapply(all_expr, rownames))
  
  combined_expr <- do.call(cbind, lapply(all_expr, function(x) x[common_genes, ]))
  combined_metadata <- do.call(rbind, all_metadata)
  
  # 批次校正
  combined_metadata$batch <- rep(names(all_expr), sapply(all_expr, ncol))
  corrected_expr <- batch_correction(combined_expr, combined_metadata)
  
  # 保存处理后的数据
  saveRDS(corrected_expr, file.path(output_dir, "neta_expression_matrix.rds"))
  saveRDS(combined_metadata, file.path(output_dir, "neta_metadata.rds"))
  
  cat("Data processing completed!\n")
  cat("Expression matrix dimensions:", dim(corrected_expr), "\n")
  cat("Metadata dimensions:", dim(combined_metadata), "\n")
  
  return(list(expression = corrected_expr, metadata = combined_metadata))
}

# 9. 真实数据收集和处理的完整流程
collect_and_process_real_neta_data <- function() {
  cat("🧬 NETA真实数据收集和处理完整流程\n")
  cat("=" %R% 50, "\n")
  
  # 步骤1: 真实数据收集
  cat("步骤1: 收集真实存在的神经内分泌肿瘤数据\n")
  source("R_scripts/real_datasets.R")
  
  # 处理真实数据集
  datasets <- process_real_datasets()
  
  if (length(datasets) == 0) {
    cat("❌ 未找到符合条件的数据集\n")
    return(NULL)
  }
  
  # 步骤2: 数据预处理
  cat("\n步骤2: 数据预处理\n")
  geo_ids <- sapply(datasets, function(x) x$geo_id)
  neta_data <- process_neta_data(geo_ids)
  
  # 步骤3: 质量评估
  cat("\n步骤3: 数据质量评估\n")
  quality_metrics <- list()
  for (dataset in datasets) {
    cat("评估数据集:", dataset$geo_id, "\n")
    quality_metrics[[dataset$geo_id]] <- assess_real_data_quality(
      dataset$data$expression, 
      dataset$data$metadata,
      dataset$geo_id
    )
  }
  
  # 步骤4: 差异表达分析
  cat("\n步骤4: 差异表达分析\n")
  de_results <- differential_expression(
    neta_data$expression, 
    neta_data$metadata, 
    group_var = "tumor_type"
  )
  
  # 步骤5: 通路分析
  cat("\n步骤5: 通路分析\n")
  gsea_results <- gene_set_enrichment(de_results$all_results)
  
  # 步骤6: 保存结果
  cat("\n步骤6: 保存分析结果\n")
  saveRDS(neta_data, "data/processed/neta_combined_data.rds")
  saveRDS(de_results, "data/processed/de_results.rds")
  saveRDS(gsea_results, "data/processed/gsea_results.rds")
  saveRDS(quality_metrics, "data/processed/quality_metrics.rds")
  
  # 创建数据清单
  inventory <- create_real_data_inventory()
  
  cat("🎉 NETA真实数据处理完成！\n")
  cat("   处理数据集数量:", length(datasets), "\n")
  cat("   总样本数:", ncol(neta_data$expression), "\n")
  cat("   总基因数:", nrow(neta_data$expression), "\n")
  cat("   数据清单已创建\n")
  
  return(list(
    datasets = datasets,
    combined_data = neta_data,
    de_results = de_results,
    gsea_results = gsea_results,
    quality_metrics = quality_metrics,
    inventory = inventory
  ))
}

# 10. 示例使用
if (FALSE) {  # 设置为TRUE来运行示例
  # 运行完整的数据收集和处理流程（推荐）
  results <- collect_and_process_real_neta_data()
  
  # 或者单独运行特定步骤
  # 步骤1: 只收集真实数据
  source("R_scripts/real_datasets.R")
  datasets <- process_real_datasets()
  
  # 步骤2: 只处理特定数据集
  geo_ids <- c("GSE73338", "GSE98894", "GSE103174")  # 真实存在的GEO ID
  neta_data <- process_neta_data(geo_ids)
  
  # 步骤3: 只进行差异表达分析
  de_results <- differential_expression(
    neta_data$expression, 
    neta_data$metadata, 
    group_var = "tumor_type"
  )
  
  # 步骤4: 创建数据清单
  inventory <- create_real_data_inventory()
}
