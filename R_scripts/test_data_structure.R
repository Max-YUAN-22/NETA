# Simple test script to check GSE182407 data structure

# Read one sample file
sample_file <- "data/raw/GSE182407/GSE182407_GSM5528434_LN_C1_processed_data.txt.gz_processed.csv"
data <- read.csv(sample_file, row.names = 1)

cat("数据维度:", dim(data), "\n")
cat("列名:", colnames(data), "\n")
cat("前5行:\n")
print(head(data, 5))

cat("Frag_count列类型:", class(data$Frag_count), "\n")
cat("Frag_count列长度:", length(data$Frag_count), "\n")
cat("Frag_count前10个值:", head(data$Frag_count, 10), "\n")

cat("Gene_symbol列类型:", class(data$Gene_symbol), "\n")
cat("Gene_symbol列长度:", length(data$Gene_symbol), "\n")
cat("Gene_symbol前10个值:", head(data$Gene_symbol, 10), "\n")
