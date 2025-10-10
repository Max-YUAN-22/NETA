#!/usr/bin/env Rscript
# 数据质量验证和统计报告

library(RSQLite)
library(DBI)
library(jsonlite)
library(dplyr)

# 数据库文件路径
db_path <- "neta_data.sqlite"

# 连接数据库
conn <- dbConnect(RSQLite::SQLite(), db_path)

# 生成数据质量报告
generate_quality_report <- function(conn) {
  cat("=== NETA数据质量报告 ===\n")
  
  # 基本统计
  datasets_count <- dbGetQuery(conn, "SELECT COUNT(*) as count FROM datasets")$count
  samples_count <- dbGetQuery(conn, "SELECT COUNT(*) as count FROM samples")$count
  genes_count <- dbGetQuery(conn, "SELECT COUNT(*) as count FROM genes")$count
  expressions_count <- dbGetQuery(conn, "SELECT COUNT(*) as count FROM gene_expression")$count
  
  cat("📊 基本统计:\n")
  cat("  数据集数量:", datasets_count, "\n")
  cat("  样本数量:", samples_count, "\n")
  cat("  基因数量:", genes_count, "\n")
  cat("  表达记录数量:", expressions_count, "\n\n")
  
  # 数据集质量分析
  cat("🔍 数据集质量分析:\n")
  
  # 按组织类型统计
  tissue_stats <- dbGetQuery(conn, "
    SELECT tissue_type, COUNT(*) as count 
    FROM datasets 
    GROUP BY tissue_type 
    ORDER BY count DESC
  ")
  cat("  组织类型分布:\n")
  for (i in 1:nrow(tissue_stats)) {
    cat("    ", tissue_stats$tissue_type[i], ":", tissue_stats$count[i], "个数据集\n")
  }
  
  # 按肿瘤类型统计
  tumor_stats <- dbGetQuery(conn, "
    SELECT tumor_type, COUNT(*) as count 
    FROM datasets 
    GROUP BY tumor_type 
    ORDER BY count DESC
  ")
  cat("\n  肿瘤类型分布:\n")
  for (i in 1:nrow(tumor_stats)) {
    cat("    ", tumor_stats$tumor_type[i], ":", tumor_stats$count[i], "个数据集\n")
  }
  
  # 样本质量分析
  cat("\n🧬 样本质量分析:\n")
  
  # 样本年龄分布
  age_stats <- dbGetQuery(conn, "
    SELECT 
      CASE 
        WHEN age IS NULL THEN 'Unknown'
        WHEN age < 30 THEN '<30'
        WHEN age < 50 THEN '30-50'
        WHEN age < 70 THEN '50-70'
        ELSE '>70'
      END as age_group,
      COUNT(*) as count
    FROM samples 
    GROUP BY age_group
    ORDER BY count DESC
  ")
  cat("  年龄分布:\n")
  for (i in 1:nrow(age_stats)) {
    cat("    ", age_stats$age_group[i], ":", age_stats$count[i], "个样本\n")
  }
  
  # 性别分布
  gender_stats <- dbGetQuery(conn, "
    SELECT gender, COUNT(*) as count 
    FROM samples 
    GROUP BY gender 
    ORDER BY count DESC
  ")
  cat("\n  性别分布:\n")
  for (i in 1:nrow(gender_stats)) {
    cat("    ", gender_stats$gender[i], ":", gender_stats$count[i], "个样本\n")
  }
  
  # 基因质量分析
  cat("\n🔬 基因质量分析:\n")
  
  # 基因类型分布
  gene_type_stats <- dbGetQuery(conn, "
    SELECT gene_type, COUNT(*) as count 
    FROM genes 
    GROUP BY gene_type 
    ORDER BY count DESC
  ")
  cat("  基因类型分布:\n")
  for (i in 1:nrow(gene_type_stats)) {
    cat("    ", gene_type_stats$gene_type[i], ":", gene_type_stats$count[i], "个基因\n")
  }
  
  # 染色体分布
  chr_stats <- dbGetQuery(conn, "
    SELECT 
      CASE 
        WHEN chromosome IS NULL OR chromosome = '' THEN 'Unknown'
        ELSE chromosome
      END as chromosome,
      COUNT(*) as count 
    FROM genes 
    GROUP BY chromosome 
    ORDER BY count DESC
    LIMIT 10
  ")
  cat("\n  染色体分布 (前10):\n")
  for (i in 1:nrow(chr_stats)) {
    cat("    ", chr_stats$chromosome[i], ":", chr_stats$count[i], "个基因\n")
  }
  
  # 表达数据质量分析
  cat("\n📈 表达数据质量分析:\n")
  
  # 表达值统计
  expr_stats <- dbGetQuery(conn, "
    SELECT 
      MIN(expression_value) as min_expr,
      MAX(expression_value) as max_expr,
      AVG(expression_value) as mean_expr,
      COUNT(*) as total_records,
      COUNT(CASE WHEN expression_value > 0 THEN 1 END) as non_zero_records
    FROM gene_expression
  ")
  
  cat("  表达值统计:\n")
  cat("    最小值:", round(expr_stats$min_expr, 2), "\n")
  cat("    最大值:", round(expr_stats$max_expr, 2), "\n")
  cat("    平均值:", round(expr_stats$mean_expr, 2), "\n")
  cat("    总记录数:", expr_stats$total_records, "\n")
  cat("    非零记录数:", expr_stats$non_zero_records, "\n")
  cat("    非零比例:", round(expr_stats$non_zero_records / expr_stats$total_records * 100, 2), "%\n")
  
  # 按数据集统计表达记录
  dataset_expr_stats <- dbGetQuery(conn, "
    SELECT 
      d.geo_id,
      d.title,
      d.n_samples,
      d.n_genes,
      COUNT(ge.id) as actual_expressions
    FROM datasets d
    LEFT JOIN gene_expression ge ON d.id = ge.dataset_id
    GROUP BY d.id, d.geo_id, d.title, d.n_samples, d.n_genes
    ORDER BY actual_expressions DESC
  ")
  
  cat("\n  各数据集表达记录统计:\n")
  for (i in 1:min(5, nrow(dataset_expr_stats))) {
    cat("    ", dataset_expr_stats$geo_id[i], ":", 
        dataset_expr_stats$actual_expressions[i], "条记录\n")
  }
  
  # 数据完整性检查
  cat("\n✅ 数据完整性检查:\n")
  
  # 检查缺失数据
  missing_genes <- dbGetQuery(conn, "
    SELECT COUNT(*) as count 
    FROM genes 
    WHERE gene_symbol IS NULL OR gene_symbol = ''
  ")$count
  
  missing_samples <- dbGetQuery(conn, "
    SELECT COUNT(*) as count 
    FROM samples 
    WHERE sample_id IS NULL OR sample_id = ''
  ")$count
  
  cat("  缺失基因符号:", missing_genes, "个\n")
  cat("  缺失样本ID:", missing_samples, "个\n")
  
  # 检查数据一致性
  inconsistent_samples <- dbGetQuery(conn, "
    SELECT COUNT(*) as count
    FROM samples s
    LEFT JOIN datasets d ON s.dataset_id = d.id
    WHERE s.tissue_type != d.tissue_type
  ")$count
  
  cat("  不一致的样本-数据集关联:", inconsistent_samples, "个\n")
  
  # 生成质量评分
  quality_score <- calculate_quality_score(
    datasets_count, samples_count, genes_count, expressions_count,
    missing_genes, missing_samples, inconsistent_samples
  )
  
  cat("\n🎯 数据质量评分:", quality_score, "/100\n")
  
  if (quality_score >= 90) {
    cat("  评级: 优秀 ⭐⭐⭐⭐⭐\n")
  } else if (quality_score >= 80) {
    cat("  评级: 良好 ⭐⭐⭐⭐\n")
  } else if (quality_score >= 70) {
    cat("  评级: 一般 ⭐⭐⭐\n")
  } else {
    cat("  评级: 需要改进 ⭐⭐\n")
  }
  
  # 生成建议
  cat("\n💡 改进建议:\n")
  if (missing_genes > 0) {
    cat("  - 补充缺失的基因符号信息\n")
  }
  if (missing_samples > 0) {
    cat("  - 补充缺失的样本ID信息\n")
  }
  if (inconsistent_samples > 0) {
    cat("  - 修正样本-数据集关联不一致问题\n")
  }
  if (expr_stats$non_zero_records / expr_stats$total_records < 0.5) {
    cat("  - 考虑过滤低表达基因以提高数据质量\n")
  }
  
  return(list(
    datasets_count = datasets_count,
    samples_count = samples_count,
    genes_count = genes_count,
    expressions_count = expressions_count,
    quality_score = quality_score,
    tissue_stats = tissue_stats,
    tumor_stats = tumor_stats,
    age_stats = age_stats,
    gender_stats = gender_stats,
    gene_type_stats = gene_type_stats,
    chr_stats = chr_stats,
    expr_stats = expr_stats,
    dataset_expr_stats = dataset_expr_stats
  ))
}

# 计算质量评分
calculate_quality_score <- function(datasets, samples, genes, expressions, 
                                   missing_genes, missing_samples, inconsistent_samples) {
  # 基础分数
  base_score <- 50
  
  # 数据量加分
  data_score <- min(20, datasets * 1 + samples / 1000 + genes / 10000 + expressions / 1000000)
  
  # 数据完整性减分
  completeness_penalty <- (missing_genes + missing_samples + inconsistent_samples) * 2
  
  # 计算最终分数
  final_score <- base_score + data_score - completeness_penalty
  
  return(max(0, min(100, round(final_score))))
}

# 生成JSON格式的详细报告
generate_json_report <- function(conn) {
  # 计算缺失数据
  missing_genes <- dbGetQuery(conn, "
    SELECT COUNT(*) as count 
    FROM genes 
    WHERE gene_symbol IS NULL OR gene_symbol = ''
  ")$count
  
  missing_samples <- dbGetQuery(conn, "
    SELECT COUNT(*) as count 
    FROM samples 
    WHERE sample_id IS NULL OR sample_id = ''
  ")$count
  # 基本统计
  basic_stats <- list(
    datasets = dbGetQuery(conn, "SELECT COUNT(*) as count FROM datasets")$count,
    samples = dbGetQuery(conn, "SELECT COUNT(*) as count FROM samples")$count,
    genes = dbGetQuery(conn, "SELECT COUNT(*) as count FROM genes")$count,
    expressions = dbGetQuery(conn, "SELECT COUNT(*) as count FROM gene_expression")$count
  )
  
  # 组织类型分布
  tissue_types <- dbGetQuery(conn, "
    SELECT tissue_type as name, COUNT(*) as count 
    FROM datasets 
    GROUP BY tissue_type 
    ORDER BY count DESC
  ")
  
  # 肿瘤类型分布
  tumor_types <- dbGetQuery(conn, "
    SELECT tumor_type as name, COUNT(*) as count 
    FROM datasets 
    GROUP BY tumor_type 
    ORDER BY count DESC
  ")
  
  # 年龄分布
  age_distribution <- dbGetQuery(conn, "
    SELECT 
      CASE 
        WHEN age IS NULL THEN 'Unknown'
        WHEN age < 30 THEN '<30'
        WHEN age < 50 THEN '30-50'
        WHEN age < 70 THEN '50-70'
        ELSE '>70'
      END as age_group,
      COUNT(*) as count
    FROM samples 
    GROUP BY age_group
    ORDER BY count DESC
  ")
  
  # 性别分布
  gender_distribution <- dbGetQuery(conn, "
    SELECT gender, COUNT(*) as count 
    FROM samples 
    GROUP BY gender 
    ORDER BY count DESC
  ")
  
  # 表达数据统计
  expression_stats <- dbGetQuery(conn, "
    SELECT 
      MIN(expression_value) as min_value,
      MAX(expression_value) as max_value,
      AVG(expression_value) as mean_value,
      COUNT(*) as total_records,
      COUNT(CASE WHEN expression_value > 0 THEN 1 END) as non_zero_records
    FROM gene_expression
  ")
  
  # 数据集详细信息
  dataset_details <- dbGetQuery(conn, "
    SELECT 
      geo_id,
      title,
      tissue_type,
      tumor_type,
      n_samples,
      n_genes,
      publication_year,
      priority
    FROM datasets 
    ORDER BY priority ASC, n_samples DESC
  ")
  
  # 组装报告
  report <- list(
    timestamp = Sys.time(),
    basic_statistics = basic_stats,
    tissue_types = tissue_types,
    tumor_types = tumor_types,
    age_distribution = age_distribution,
    gender_distribution = gender_distribution,
    expression_statistics = expression_stats,
    dataset_details = dataset_details,
    quality_metrics = list(
      data_completeness = round((basic_stats$samples - missing_samples) / basic_stats$samples * 100, 2),
      expression_coverage = round(expression_stats$non_zero_records / expression_stats$total_records * 100, 2),
      dataset_diversity = nrow(tissue_types)
    )
  )
  
  return(report)
}

# 主函数
main <- function() {
  cat("开始生成数据质量报告...\n")
  
  # 生成控制台报告
  quality_data <- generate_quality_report(conn)
  
  # 生成JSON报告
  json_report <- generate_json_report(conn)
  
  # 保存JSON报告
  write_json(json_report, "data_quality_report.json", pretty = TRUE)
  cat("\n📄 详细报告已保存到: data_quality_report.json\n")
  
  # 关闭数据库连接
  dbDisconnect(conn)
  
  cat("\n=== 报告生成完成 ===\n")
  cat("数据质量评分:", quality_data$quality_score, "/100\n")
  cat("建议: 该数据集质量", 
      ifelse(quality_data$quality_score >= 80, "优秀", "良好"), 
      "，适合进行生物信息学分析\n")
}

# 运行主函数
if (!interactive()) {
  main()
}
