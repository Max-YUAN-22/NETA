# NETA Shiny App Dependencies
# 安装和加载NETA Shiny应用所需的R包

# 检查并安装CRAN包
install_if_missing <- function(package) {
  if (!require(package, character.only = TRUE)) {
    install.packages(package, dependencies = TRUE)
    library(package, character.only = TRUE)
  }
}

# 检查并安装Bioconductor包
install_bioc_if_missing <- function(package) {
  if (!require(package, character.only = TRUE)) {
    if (!require("BiocManager", quietly = TRUE)) {
      install.packages("BiocManager")
    }
    BiocManager::install(package)
    library(package, character.only = TRUE)
  }
}

# CRAN包列表
cran_packages <- c(
  "shiny",
  "shinydashboard",
  "DT",
  "plotly",
  "ggplot2",
  "dplyr",
  "tidyr",
  "readr",
  "stringr",
  "RColorBrewer",
  "VennDiagram",
  "pheatmap",
  "corrplot",
  "survival",
  "survminer",
  "knitr",
  "rmarkdown"
)

# Bioconductor包列表
bioc_packages <- c(
  "limma",
  "edgeR",
  "DESeq2",
  "SummarizedExperiment",
  "AnnotationDbi",
  "org.Hs.eg.db",
  "GEOquery",
  "TCGAbiolinks",
  "clusterProfiler",
  "pathview",
  "KEGG.db",
  "GO.db",
  "ComplexHeatmap",
  "circlize",
  "sva",
  "fgsea"
)

# 安装CRAN包
cat("Installing CRAN packages...\n")
for (pkg in cran_packages) {
  install_if_missing(pkg)
}

# 安装Bioconductor包
cat("Installing Bioconductor packages...\n")
for (pkg in bioc_packages) {
  install_bioc_if_missing(pkg)
}

cat("All packages installed successfully!\n")

# 验证安装
cat("Verifying package installation...\n")
all_packages <- c(cran_packages, bioc_packages)
missing_packages <- c()

for (pkg in all_packages) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    missing_packages <- c(missing_packages, pkg)
  }
}

if (length(missing_packages) > 0) {
  cat("Warning: The following packages could not be loaded:\n")
  cat(paste(missing_packages, collapse = ", "), "\n")
} else {
  cat("All packages loaded successfully!\n")
}
