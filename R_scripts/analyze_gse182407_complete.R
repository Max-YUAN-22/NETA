# R script to merge GSE182407 data and perform DESeq2 analysis

# Install and load necessary packages
if (!requireNamespace("BiocManager", quietly = TRUE))
    install.packages("BiocManager")
if (!requireNamespace("DESeq2", quietly = TRUE))
    BiocManager::install("DESeq2")
if (!requireNamespace("ggplot2", quietly = TRUE))
    install.packages("ggplot2")
if (!requireNamespace("pheatmap", quietly = TRUE))
    install.packages("pheatmap")
if (!requireNamespace("RColorBrewer", quietly = TRUE))
    install.packages("RColorBrewer")
if (!requireNamespace("EnhancedVolcano", quietly = TRUE))
    BiocManager::install("EnhancedVolcano")

library(DESeq2)
library(ggplot2)
library(pheatmap)
library(RColorBrewer)
library(EnhancedVolcano)

# Define GEO ID and directories
geo_id <- "GSE182407"
data_dir <- file.path("data", "raw", geo_id)
results_dir <- file.path("data", "processed", "analysis_results", "deseq2", geo_id)
dir.create(results_dir, recursive = TRUE, showWarnings = FALSE)

cat("=== GSE182407 DESeq2分析 ===\n")

# Function to merge individual sample files into expression matrix
merge_sample_files <- function(data_dir) {
    cat("=== 合并样本文件 ===\n")
    
    # Get all processed CSV files
    csv_files <- list.files(data_dir, pattern = "_processed\\.csv$", full.names = TRUE)
    cat("找到", length(csv_files), "个样本文件\n")
    
    if (length(csv_files) == 0) {
        cat("❌ 未找到样本文件\n")
        return(NULL)
    }
    
    # Read first file to get gene information
    first_file <- read.csv(csv_files[1], row.names = 1)
    gene_symbols <- first_file$Gene_symbol
    cat("基因数量:", length(gene_symbols), "\n")
    
    # Initialize expression matrix
    expr_matrix <- matrix(0, nrow = length(gene_symbols), ncol = length(csv_files))
    rownames(expr_matrix) <- gene_symbols
    colnames(expr_matrix) <- gsub(".*GSE182407_|_processed_data\\.txt\\.gz_processed\\.csv$", "", basename(csv_files))
    
    # Read each file and extract Frag_count
    for (i in 1:length(csv_files)) {
        sample_data <- read.csv(csv_files[i], row.names = 1)
        expr_matrix[, i] <- sample_data$Frag_count
        cat("处理样本", i, ":", colnames(expr_matrix)[i], "\n")
    }
    
    cat("表达矩阵维度:", dim(expr_matrix), "\n")
    cat("数据范围:", min(expr_matrix), "-", max(expr_matrix), "\n")
    
    return(expr_matrix)
}

# Function to create phenotype data
create_phenotype_data <- function(expr_matrix) {
    cat("=== 创建表型数据 ===\n")
    
    sample_names <- colnames(expr_matrix)
    
    # Extract grouping information from sample names
    # Sample names like: LN_C1, LN_C2, LN_C3, LN_Y09_1, LN_Y09_2, LN_Y09_3, etc.
    
    pheno_data <- data.frame(
        sample_id = sample_names,
        cell_line = sapply(strsplit(sample_names, "_"), `[`, 1),
        treatment = sapply(strsplit(sample_names, "_"), function(x) {
            if (length(x) >= 2) {
                if (x[2] == "C") return("Control")
                if (x[2] == "Y09") return("YAP1_KD")
                if (x[2] == "Y99") return("YAP1_KD")
                if (x[2] == "E") return("Control")
                if (x[2] == "Y") return("YAP1_OE")
            }
            return("Unknown")
        }),
        stringsAsFactors = FALSE
    )
    
    # Create comparison groups
    pheno_data$comparison_group <- ifelse(pheno_data$treatment == "Control", "Control", "YAP1_intervention")
    pheno_data$comparison_group <- factor(pheno_data$comparison_group, levels = c("Control", "YAP1_intervention"))
    
    # Create combined group for cell line specific analysis
    pheno_data$cell_line_group <- paste(pheno_data$cell_line, pheno_data$treatment, sep = "_")
    
    rownames(pheno_data) <- pheno_data$sample_id
    
    cat("表型数据:\n")
    print(pheno_data)
    
    cat("\n分组统计:\n")
    print(table(pheno_data$comparison_group))
    print(table(pheno_data$cell_line))
    print(table(pheno_data$treatment))
    
    return(pheno_data)
}

# Function to perform DESeq2 analysis
perform_deseq2_analysis <- function(expr_matrix, pheno_data, analysis_name) {
    cat("\n=== DESeq2分析:", analysis_name, "===\n")
    
    # Filter genes with zero counts
    expr_matrix_filtered <- expr_matrix[rowSums(expr_matrix) > 0, ]
    cat("过滤后基因数:", nrow(expr_matrix_filtered), "\n")
    
    # Check sample order
    stopifnot(all(rownames(pheno_data) == colnames(expr_matrix_filtered)))
    
    # Check for sufficient replicates
    group_counts <- table(pheno_data$comparison_group)
    cat("分组样本数:\n")
    print(group_counts)
    
    if (any(group_counts < 2)) {
        cat("❌ 警告: 某些分组样本数少于2个\n")
        return(NULL)
    }
    
    # Create DESeq2 object
    dds <- DESeqDataSetFromMatrix(
        countData = expr_matrix_filtered,
        colData = pheno_data,
        design = ~ comparison_group
    )
    
    # Run DESeq2
    dds <- DESeq(dds)
    
    # Get results
    res <- results(dds, contrast = c("comparison_group", "YAP1_intervention", "Control"))
    res <- as.data.frame(res)
    res <- res[order(res$padj), ]
    
    # Filter significant genes
    significant_genes <- subset(res, padj < 0.05 & abs(log2FoldChange) > 1)
    cat("显著差异基因数:", nrow(significant_genes), "\n")
    cat("上调基因数:", sum(significant_genes$log2FoldChange > 0), "\n")
    cat("下调基因数:", sum(significant_genes$log2FoldChange < 0), "\n")
    
    # Save results
    write.csv(res, file.path(results_dir, paste0("deseq2_results_", analysis_name, ".csv")))
    write.csv(significant_genes, file.path(results_dir, paste0("significant_genes_", analysis_name, ".csv")))
    
    # Generate plots
    generate_plots(dds, res, significant_genes, analysis_name)
    
    return(list(
        results = res,
        significant_genes = significant_genes,
        significant_count = nrow(significant_genes),
        upregulated_count = sum(significant_genes$log2FoldChange > 0),
        downregulated_count = sum(significant_genes$log2FoldChange < 0)
    ))
}

# Function to generate plots
generate_plots <- function(dds, res, significant_genes, analysis_name) {
    cat("生成图表:", analysis_name, "\n")
    
    # Volcano Plot
    png(file.path(results_dir, paste0("volcano_plot_", analysis_name, ".png")), 
        width = 1000, height = 1000, res = 150)
    print(EnhancedVolcano(res,
                        lab = rownames(res),
                        x = 'log2FoldChange',
                        y = 'padj',
                        title = paste0('GSE182407 ', analysis_name, ' Volcano Plot'),
                        pCutoff = 0.05,
                        FCcutoff = 1,
                        pointSize = 2.0,
                        labSize = 4.0,
                        colAlpha = 1,
                        legendLabels=c('Not significant','Log2 FC','p-value', 'p-value & Log2 FC'),
                        col=c('grey30', 'forestgreen', 'royalblue', 'red2'),
                        drawConnectors = TRUE,
                        widthConnectors = 0.5,
                        colConnectors = 'black',
                        gridlines.major = FALSE,
                        gridlines.minor = FALSE,
                        border = 'full',
                        borderWidth = 1.5,
                        bordeCol = 'black'))
    dev.off()
    
    # MA Plot
    png(file.path(results_dir, paste0("ma_plot_", analysis_name, ".png")), 
        width = 1000, height = 1000, res = 150)
    plotMA(dds, ylim = c(-5, 5), main = paste0('GSE182407 ', analysis_name, ' MA Plot'))
    dev.off()
    
    # PCA Plot
    vsd <- varianceStabilizingTransformation(dds, blind = FALSE)
    pca_data <- plotPCA(vsd, intgroup = c("comparison_group", "cell_line"), returnData = TRUE)
    percentVar <- round(100 * attr(pca_data, "percentVar"))
    
    pca_plot <- ggplot(pca_data, aes(PC1, PC2, color = comparison_group, shape = cell_line)) +
        geom_point(size = 3) +
        xlab(paste0("PC1: ", percentVar[1], "% variance")) +
        ylab(paste0("PC2: ", percentVar[2], "% variance")) +
        ggtitle(paste0('GSE182407 ', analysis_name, ' PCA Plot')) +
        coord_fixed() +
        theme_minimal() +
        theme(plot.title = element_text(hjust = 0.5, size = 16, face = "bold"),
              axis.title = element_text(size = 14),
              axis.text = element_text(size = 12),
              legend.title = element_text(size = 14),
              legend.text = element_text(size = 12))
    
    png(file.path(results_dir, paste0("pca_plot_", analysis_name, ".png")), 
        width = 1000, height = 1000, res = 150)
    print(pca_plot)
    dev.off()
    
    # Heatmap
    if (nrow(significant_genes) > 0) {
        top_genes <- head(rownames(significant_genes), 50)
        norm_counts <- assay(vsd)[top_genes, ]
        
        annotation_col <- data.frame(
            Group = colData(dds)$comparison_group,
            CellLine = colData(dds)$cell_line
        )
        rownames(annotation_col) <- colnames(norm_counts)
        
        ann_colors <- list(
            Group = c(Control = "blue", YAP1_intervention = "red"),
            CellLine = c(LN = "purple", DU = "orange", H660 = "green")
        )
        
        png(file.path(results_dir, paste0("heatmap_", analysis_name, ".png")), 
            width = 1200, height = 1200, res = 150)
        pheatmap(norm_counts, 
                 cluster_rows = TRUE, 
                 cluster_cols = TRUE, 
                 show_rownames = TRUE, 
                 show_colnames = TRUE,
                 annotation_col = annotation_col,
                 annotation_colors = ann_colors,
                 fontsize_row = 8, 
                 fontsize_col = 8,
                 main = paste0('GSE182407 ', analysis_name, ' Heatmap of Top Significant Genes'),
                 color = colorRampPalette(rev(brewer.pal(n = 7, name = "RdYlBu")))(100))
        dev.off()
    }
    
    cat("✅ 图表生成完成\n")
}

# Main execution
cat("开始分析GSE182407...\n")

# Merge sample files
expr_matrix <- merge_sample_files(data_dir)

if (!is.null(expr_matrix)) {
    # Create phenotype data
    pheno_data <- create_phenotype_data(expr_matrix)
    
    # Save merged data
    write.csv(expr_matrix, file.path(data_dir, paste0(geo_id, "_expression_matrix_merged.csv")))
    write.csv(pheno_data, file.path(data_dir, paste0(geo_id, "_phenotype_data_merged.csv")))
    
    # Perform overall DESeq2 analysis
    overall_results <- perform_deseq2_analysis(expr_matrix, pheno_data, "overall")
    
    # Perform cell line specific analyses
    cell_lines <- unique(pheno_data$cell_line)
    cell_line_results <- list()
    
    for (cell_line in cell_lines) {
        cat("\n=== 分析细胞系:", cell_line, "===\n")
        
        # Subset data for this cell line
        cell_line_samples <- pheno_data$cell_line == cell_line
        cell_line_pheno <- pheno_data[cell_line_samples, ]
        cell_line_expr <- expr_matrix[, cell_line_samples]
        
        cat("样本数:", nrow(cell_line_pheno), "\n")
        
        if (nrow(cell_line_pheno) >= 4) {  # At least 2 samples per group
            cell_line_results[[cell_line]] <- perform_deseq2_analysis(
                cell_line_expr, cell_line_pheno, paste0("cell_line_", cell_line)
            )
        } else {
            cat("样本数不足，跳过", cell_line, "分析\n")
        }
    }
    
    # Summary
    cat("\n=== 分析结果总结 ===\n")
    if (!is.null(overall_results)) {
        cat("整体分析:\n")
        cat("  显著差异基因数:", overall_results$significant_count, "\n")
        cat("  上调基因数:", overall_results$upregulated_count, "\n")
        cat("  下调基因数:", overall_results$downregulated_count, "\n")
    }
    
    for (cell_line in names(cell_line_results)) {
        if (!is.null(cell_line_results[[cell_line]])) {
            cat("\n", cell_line, "细胞系分析:\n")
            cat("  显著差异基因数:", cell_line_results[[cell_line]]$significant_count, "\n")
            cat("  上调基因数:", cell_line_results[[cell_line]]$upregulated_count, "\n")
            cat("  下调基因数:", cell_line_results[[cell_line]]$downregulated_count, "\n")
        }
    }
    
    cat("\n✅ GSE182407分析完成！\n")
    cat("结果保存在:", results_dir, "\n")
    
} else {
    cat("❌ 无法合并样本文件\n")
}
