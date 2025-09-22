# Fixed script to merge GSE182407 data

# Get only the sample CSV files (exclude expression matrix files)
csv_files <- list.files("data/raw/GSE182407", pattern = "_processed_data\\.txt\\.gz_processed\\.csv$", full.names = TRUE)
cat("找到", length(csv_files), "个样本文件\n")

# Read first file to get gene info
first_data <- read.csv(csv_files[1], row.names = 1)
gene_symbols <- first_data$Gene_symbol
cat("基因数量:", length(gene_symbols), "\n")

# Initialize expression matrix
expr_matrix <- matrix(0, nrow = length(gene_symbols), ncol = length(csv_files))
rownames(expr_matrix) <- gene_symbols
colnames(expr_matrix) <- gsub(".*GSE182407_|_processed_data\\.txt\\.gz_processed\\.csv$", "", basename(csv_files))

# Process each file
for (i in 1:length(csv_files)) {
    cat("处理文件", i, ":", basename(csv_files[i]), "\n")
    
    sample_data <- read.csv(csv_files[i], row.names = 1)
    
    # Check if gene symbols match
    if (all(gene_symbols == sample_data$Gene_symbol)) {
        expr_matrix[, i] <- sample_data$Frag_count
        cat("  成功，样本名:", colnames(expr_matrix)[i], "\n")
    } else {
        cat("  基因符号不匹配，跳过\n")
    }
}

cat("最终表达矩阵维度:", dim(expr_matrix), "\n")
cat("数据范围:", min(expr_matrix), "-", max(expr_matrix), "\n")

# Save the merged matrix
write.csv(expr_matrix, "data/raw/GSE182407/GSE182407_expression_matrix_merged.csv")
cat("已保存合并的表达矩阵\n")

# Create phenotype data
sample_names <- colnames(expr_matrix)
pheno_data <- data.frame(
    sample_id = sample_names,
    cell_line = sapply(strsplit(sample_names, "_"), function(x) x[2]),
    treatment = sapply(strsplit(sample_names, "_"), function(x) {
        if (length(x) >= 3) {
            treatment_code <- x[3]
            if (grepl("^C", treatment_code)) return("Control")
            if (grepl("Y09", treatment_code)) return("YAP1_KD")
            if (grepl("Y99", treatment_code)) return("YAP1_KD")
            if (grepl("^E", treatment_code)) return("Control")
            if (grepl("^Y", treatment_code)) return("YAP1_OE")
        }
        return("Unknown")
    }),
    stringsAsFactors = FALSE
)

pheno_data$comparison_group <- ifelse(pheno_data$treatment == "Control", "Control", "YAP1_intervention")
pheno_data$comparison_group <- factor(pheno_data$comparison_group, levels = c("Control", "YAP1_intervention"))

rownames(pheno_data) <- pheno_data$sample_id

cat("表型数据:\n")
print(pheno_data)

cat("\n分组统计:\n")
print(table(pheno_data$comparison_group))
print(table(pheno_data$cell_line))
print(table(pheno_data$treatment))

# Save phenotype data
write.csv(pheno_data, "data/raw/GSE182407/GSE182407_phenotype_data_merged.csv")
cat("已保存表型数据\n")
