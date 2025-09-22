-- NETA数据库初始化脚本
-- MySQL数据库创建和表结构定义

-- 创建数据库
CREATE DATABASE IF NOT EXISTS neta_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE neta_db;

-- 1. 数据集表
CREATE TABLE IF NOT EXISTS datasets (
    id INT PRIMARY KEY AUTO_INCREMENT,
    geo_id VARCHAR(20) UNIQUE NOT NULL COMMENT 'GEO数据集ID',
    title TEXT NOT NULL COMMENT '数据集标题',
    description TEXT COMMENT '数据集描述',
    tissue_type VARCHAR(100) COMMENT '组织类型',
    tumor_type VARCHAR(100) COMMENT '肿瘤类型',
    platform VARCHAR(200) COMMENT '测序平台',
    n_samples INT COMMENT '样本数量',
    n_genes INT COMMENT '基因数量',
    publication_year YEAR COMMENT '发表年份',
    reference_pmid VARCHAR(20) COMMENT 'PubMed ID',
    data_source VARCHAR(50) DEFAULT 'GEO' COMMENT '数据来源',
    file_path VARCHAR(500) COMMENT '数据文件路径',
    status ENUM('active', 'inactive', 'processing') DEFAULT 'active' COMMENT '状态',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_geo_id (geo_id),
    INDEX idx_tissue_type (tissue_type),
    INDEX idx_tumor_type (tumor_type),
    INDEX idx_publication_year (publication_year)
) ENGINE=InnoDB COMMENT='神经内分泌肿瘤数据集信息表';

-- 2. 样本信息表
CREATE TABLE IF NOT EXISTS samples (
    id INT PRIMARY KEY AUTO_INCREMENT,
    dataset_id INT NOT NULL COMMENT '数据集ID',
    sample_id VARCHAR(100) NOT NULL COMMENT '样本ID',
    sample_name VARCHAR(200) COMMENT '样本名称',
    tissue_type VARCHAR(100) COMMENT '组织类型',
    tumor_type VARCHAR(100) COMMENT '肿瘤类型',
    tumor_subtype VARCHAR(100) COMMENT '肿瘤亚型',
    grade VARCHAR(10) COMMENT '分级',
    stage VARCHAR(10) COMMENT '分期',
    age INT COMMENT '年龄',
    gender ENUM('Male', 'Female', 'Unknown') COMMENT '性别',
    survival_status ENUM('Alive', 'Dead', 'Unknown') COMMENT '生存状态',
    survival_time INT COMMENT '生存时间(天)',
    treatment_type VARCHAR(200) COMMENT '治疗类型',
    treatment_response VARCHAR(100) COMMENT '治疗反应',
    metastasis_status ENUM('Yes', 'No', 'Unknown') COMMENT '转移状态',
    primary_site VARCHAR(100) COMMENT '原发部位',
    sample_source VARCHAR(100) COMMENT '样本来源',
    collection_date DATE COMMENT '收集日期',
    storage_method VARCHAR(100) COMMENT '保存方法',
    quality_score DECIMAL(3,2) COMMENT '质量评分',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (dataset_id) REFERENCES datasets(id) ON DELETE CASCADE,
    INDEX idx_dataset_sample (dataset_id, sample_id),
    INDEX idx_tumor_type (tumor_type),
    INDEX idx_grade (grade),
    INDEX idx_stage (stage),
    INDEX idx_survival (survival_status, survival_time)
) ENGINE=InnoDB COMMENT='样本详细信息表';

-- 3. 基因信息表
CREATE TABLE IF NOT EXISTS genes (
    id INT PRIMARY KEY AUTO_INCREMENT,
    gene_id VARCHAR(50) UNIQUE NOT NULL COMMENT '基因ID',
    gene_symbol VARCHAR(50) COMMENT '基因符号',
    gene_name TEXT COMMENT '基因全名',
    chromosome VARCHAR(10) COMMENT '染色体',
    start_position BIGINT COMMENT '起始位置',
    end_position BIGINT COMMENT '结束位置',
    strand ENUM('+', '-', '?') COMMENT '链方向',
    gene_type VARCHAR(50) COMMENT '基因类型',
    description TEXT COMMENT '基因描述',
    aliases TEXT COMMENT '基因别名',
    entrez_id VARCHAR(20) COMMENT 'Entrez ID',
    ensembl_id VARCHAR(50) COMMENT 'Ensembl ID',
    uniprot_id VARCHAR(20) COMMENT 'UniProt ID',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_symbol (gene_symbol),
    INDEX idx_chromosome (chromosome),
    INDEX idx_gene_type (gene_type),
    INDEX idx_entrez_id (entrez_id),
    INDEX idx_ensembl_id (ensembl_id)
) ENGINE=InnoDB COMMENT='基因信息表';

-- 4. 基因表达表
CREATE TABLE IF NOT EXISTS gene_expression (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    dataset_id INT NOT NULL COMMENT '数据集ID',
    sample_id VARCHAR(100) NOT NULL COMMENT '样本ID',
    gene_id VARCHAR(50) NOT NULL COMMENT '基因ID',
    gene_symbol VARCHAR(50) COMMENT '基因符号',
    expression_value DECIMAL(15,3) COMMENT '表达值',
    log2_expression DECIMAL(10,3) COMMENT 'Log2表达值',
    normalized_value DECIMAL(15,3) COMMENT '标准化值',
    percentile_rank DECIMAL(5,2) COMMENT '百分位排名',
    is_expressed BOOLEAN DEFAULT FALSE COMMENT '是否表达',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (dataset_id) REFERENCES datasets(id) ON DELETE CASCADE,
    FOREIGN KEY (gene_id) REFERENCES genes(gene_id) ON DELETE CASCADE,
    INDEX idx_dataset_gene (dataset_id, gene_id),
    INDEX idx_sample_gene (sample_id, gene_id),
    INDEX idx_gene_symbol (gene_symbol),
    INDEX idx_expression_value (expression_value),
    INDEX idx_is_expressed (is_expressed)
) ENGINE=InnoDB COMMENT='基因表达数据表';

-- 5. 差异表达分析结果表
CREATE TABLE IF NOT EXISTS differential_expression (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    dataset_id INT NOT NULL COMMENT '数据集ID',
    gene_id VARCHAR(50) NOT NULL COMMENT '基因ID',
    gene_symbol VARCHAR(50) COMMENT '基因符号',
    comparison_group1 VARCHAR(200) COMMENT '比较组1',
    comparison_group2 VARCHAR(200) COMMENT '比较组2',
    log2_fold_change DECIMAL(10,3) COMMENT 'Log2倍数变化',
    fold_change DECIMAL(10,3) COMMENT '倍数变化',
    p_value DECIMAL(15,10) COMMENT 'P值',
    adjusted_p_value DECIMAL(15,10) COMMENT '校正P值',
    q_value DECIMAL(15,10) COMMENT 'Q值',
    base_mean DECIMAL(15,3) COMMENT '基础均值',
    lfc_se DECIMAL(10,3) COMMENT 'LFC标准误',
    stat DECIMAL(10,3) COMMENT '统计量',
    significance_level ENUM('highly_significant', 'significant', 'not_significant') COMMENT '显著性水平',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (dataset_id) REFERENCES datasets(id) ON DELETE CASCADE,
    FOREIGN KEY (gene_id) REFERENCES genes(gene_id) ON DELETE CASCADE,
    INDEX idx_dataset_comparison (dataset_id, comparison_group1, comparison_group2),
    INDEX idx_gene_symbol (gene_symbol),
    INDEX idx_log2_fold_change (log2_fold_change),
    INDEX idx_p_value (p_value),
    INDEX idx_significance (significance_level)
) ENGINE=InnoDB COMMENT='差异表达分析结果表';

-- 6. 通路信息表
CREATE TABLE IF NOT EXISTS pathways (
    id INT PRIMARY KEY AUTO_INCREMENT,
    pathway_id VARCHAR(50) UNIQUE NOT NULL COMMENT '通路ID',
    pathway_name VARCHAR(500) COMMENT '通路名称',
    pathway_source VARCHAR(50) COMMENT '通路来源',
    pathway_category VARCHAR(100) COMMENT '通路类别',
    description TEXT COMMENT '通路描述',
    gene_count INT COMMENT '基因数量',
    url VARCHAR(500) COMMENT '通路URL',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_source (pathway_source),
    INDEX idx_category (pathway_category),
    INDEX idx_gene_count (gene_count)
) ENGINE=InnoDB COMMENT='通路信息表';

-- 7. 通路基因关联表
CREATE TABLE IF NOT EXISTS pathway_genes (
    id INT PRIMARY KEY AUTO_INCREMENT,
    pathway_id VARCHAR(50) NOT NULL COMMENT '通路ID',
    gene_id VARCHAR(50) NOT NULL COMMENT '基因ID',
    gene_symbol VARCHAR(50) COMMENT '基因符号',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (pathway_id) REFERENCES pathways(pathway_id) ON DELETE CASCADE,
    FOREIGN KEY (gene_id) REFERENCES genes(gene_id) ON DELETE CASCADE,
    INDEX idx_pathway (pathway_id),
    INDEX idx_gene (gene_id),
    INDEX idx_gene_symbol (gene_symbol),
    UNIQUE KEY unique_pathway_gene (pathway_id, gene_id)
) ENGINE=InnoDB COMMENT='通路基因关联表';

-- 8. 通路富集分析结果表
CREATE TABLE IF NOT EXISTS pathway_enrichment (
    id INT PRIMARY KEY AUTO_INCREMENT,
    dataset_id INT NOT NULL COMMENT '数据集ID',
    analysis_id VARCHAR(100) COMMENT '分析ID',
    pathway_id VARCHAR(50) NOT NULL COMMENT '通路ID',
    pathway_name VARCHAR(500) COMMENT '通路名称',
    gene_count INT COMMENT '基因数量',
    background_count INT COMMENT '背景基因数量',
    p_value DECIMAL(15,10) COMMENT 'P值',
    adjusted_p_value DECIMAL(15,10) COMMENT '校正P值',
    q_value DECIMAL(15,10) COMMENT 'Q值',
    enrichment_score DECIMAL(10,3) COMMENT '富集分数',
    normalized_enrichment_score DECIMAL(10,3) COMMENT '标准化富集分数',
    leading_edge_genes TEXT COMMENT '前缘基因',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (dataset_id) REFERENCES datasets(id) ON DELETE CASCADE,
    FOREIGN KEY (pathway_id) REFERENCES pathways(pathway_id) ON DELETE CASCADE,
    INDEX idx_dataset_analysis (dataset_id, analysis_id),
    INDEX idx_pathway (pathway_id),
    INDEX idx_p_value (p_value),
    INDEX idx_enrichment_score (enrichment_score)
) ENGINE=InnoDB COMMENT='通路富集分析结果表';

-- 9. 生存分析结果表
CREATE TABLE IF NOT EXISTS survival_analysis (
    id INT PRIMARY KEY AUTO_INCREMENT,
    dataset_id INT NOT NULL COMMENT '数据集ID',
    gene_id VARCHAR(50) NOT NULL COMMENT '基因ID',
    gene_symbol VARCHAR(50) COMMENT '基因符号',
    analysis_type ENUM('overall_survival', 'progression_free_survival', 'disease_free_survival') COMMENT '分析类型',
    cutoff_method VARCHAR(50) COMMENT '截断方法',
    cutoff_value DECIMAL(10,3) COMMENT '截断值',
    high_group_n INT COMMENT '高表达组样本数',
    low_group_n INT COMMENT '低表达组样本数',
    hazard_ratio DECIMAL(10,3) COMMENT '风险比',
    hr_ci_lower DECIMAL(10,3) COMMENT 'HR置信区间下限',
    hr_ci_upper DECIMAL(10,3) COMMENT 'HR置信区间上限',
    p_value DECIMAL(15,10) COMMENT 'P值',
    log_rank_p DECIMAL(15,10) COMMENT 'Log-rank P值',
    median_survival_high INT COMMENT '高表达组中位生存时间',
    median_survival_low INT COMMENT '低表达组中位生存时间',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (dataset_id) REFERENCES datasets(id) ON DELETE CASCADE,
    FOREIGN KEY (gene_id) REFERENCES genes(gene_id) ON DELETE CASCADE,
    INDEX idx_dataset_gene (dataset_id, gene_id),
    INDEX idx_gene_symbol (gene_symbol),
    INDEX idx_analysis_type (analysis_type),
    INDEX idx_p_value (p_value),
    INDEX idx_hazard_ratio (hazard_ratio)
) ENGINE=InnoDB COMMENT='生存分析结果表';

-- 10. 分析任务表
CREATE TABLE IF NOT EXISTS analysis_tasks (
    id INT PRIMARY KEY AUTO_INCREMENT,
    dataset_id INT NOT NULL COMMENT '数据集ID',
    task_type VARCHAR(50) NOT NULL COMMENT '任务类型',
    task_name VARCHAR(200) COMMENT '任务名称',
    parameters JSON COMMENT '任务参数',
    status ENUM('pending', 'running', 'completed', 'failed') DEFAULT 'pending' COMMENT '任务状态',
    progress INT DEFAULT 0 COMMENT '进度百分比',
    result_summary TEXT COMMENT '结果摘要',
    error_message TEXT COMMENT '错误信息',
    result_file_path VARCHAR(500) COMMENT '结果文件路径',
    started_at TIMESTAMP NULL COMMENT '开始时间',
    completed_at TIMESTAMP NULL COMMENT '完成时间',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (dataset_id) REFERENCES datasets(id) ON DELETE CASCADE,
    INDEX idx_dataset_type (dataset_id, task_type),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB COMMENT='分析任务表';

-- 11. 用户表（可选，用于权限管理）
CREATE TABLE IF NOT EXISTS users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) UNIQUE NOT NULL COMMENT '用户名',
    email VARCHAR(100) UNIQUE NOT NULL COMMENT '邮箱',
    password_hash VARCHAR(255) NOT NULL COMMENT '密码哈希',
    full_name VARCHAR(100) COMMENT '全名',
    institution VARCHAR(200) COMMENT '机构',
    role ENUM('admin', 'researcher', 'viewer') DEFAULT 'viewer' COMMENT '角色',
    is_active BOOLEAN DEFAULT TRUE COMMENT '是否激活',
    last_login TIMESTAMP NULL COMMENT '最后登录时间',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_username (username),
    INDEX idx_email (email),
    INDEX idx_role (role)
) ENGINE=InnoDB COMMENT='用户表';

-- 12. 数据访问日志表
CREATE TABLE IF NOT EXISTS access_logs (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id INT COMMENT '用户ID',
    dataset_id INT COMMENT '数据集ID',
    action VARCHAR(50) COMMENT '操作类型',
    resource VARCHAR(200) COMMENT '访问资源',
    ip_address VARCHAR(45) COMMENT 'IP地址',
    user_agent TEXT COMMENT '用户代理',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (dataset_id) REFERENCES datasets(id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_dataset_id (dataset_id),
    INDEX idx_action (action),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB COMMENT='数据访问日志表';

-- 创建视图
-- 数据集概览视图
CREATE VIEW dataset_overview AS
SELECT 
    d.id,
    d.geo_id,
    d.title,
    d.tissue_type,
    d.tumor_type,
    d.n_samples,
    d.n_genes,
    d.publication_year,
    d.reference_pmid,
    COUNT(s.id) as actual_samples,
    COUNT(DISTINCT s.tumor_subtype) as tumor_subtypes,
    COUNT(DISTINCT s.grade) as grades,
    COUNT(DISTINCT s.stage) as stages,
    AVG(s.age) as avg_age,
    COUNT(CASE WHEN s.gender = 'Male' THEN 1 END) as male_count,
    COUNT(CASE WHEN s.gender = 'Female' THEN 1 END) as female_count
FROM datasets d
LEFT JOIN samples s ON d.id = s.dataset_id
GROUP BY d.id;

-- 基因表达统计视图
CREATE VIEW gene_expression_stats AS
SELECT 
    d.geo_id,
    ge.gene_symbol,
    COUNT(*) as sample_count,
    AVG(ge.expression_value) as mean_expression,
    STD(ge.expression_value) as std_expression,
    MIN(ge.expression_value) as min_expression,
    MAX(ge.expression_value) as max_expression,
    COUNT(CASE WHEN ge.is_expressed = TRUE THEN 1 END) as expressed_samples,
    COUNT(CASE WHEN ge.is_expressed = TRUE THEN 1 END) / COUNT(*) * 100 as expression_percentage
FROM gene_expression ge
JOIN datasets d ON ge.dataset_id = d.id
GROUP BY d.geo_id, ge.gene_symbol;

-- 差异表达基因统计视图
CREATE VIEW de_gene_stats AS
SELECT 
    d.geo_id,
    de.comparison_group1,
    de.comparison_group2,
    COUNT(*) as total_genes,
    COUNT(CASE WHEN de.significance_level = 'highly_significant' THEN 1 END) as highly_significant,
    COUNT(CASE WHEN de.significance_level = 'significant' THEN 1 END) as significant,
    COUNT(CASE WHEN de.log2_fold_change > 1 THEN 1 END) as upregulated,
    COUNT(CASE WHEN de.log2_fold_change < -1 THEN 1 END) as downregulated
FROM differential_expression de
JOIN datasets d ON de.dataset_id = d.id
GROUP BY d.geo_id, de.comparison_group1, de.comparison_group2;

-- 插入示例数据
INSERT INTO datasets (geo_id, title, tissue_type, tumor_type, n_samples, n_genes, publication_year, reference_pmid) VALUES
('GSE73338', 'Pancreatic neuroendocrine tumors RNA-seq analysis', 'Pancreas', 'Pancreatic NET', 15, 20000, 2015, '26340334'),
('GSE98894', 'Gastrointestinal neuroendocrine neoplasms comprehensive analysis', 'Gastrointestinal', 'GI-NET', 25, 20000, 2017, '28514442'),
('GSE103174', 'Small cell lung cancer transcriptome analysis', 'Lung', 'SCLC', 20, 20000, 2016, '27533040');

-- 插入示例基因信息
INSERT INTO genes (gene_id, gene_symbol, gene_name, chromosome, gene_type, description) VALUES
('ENSG00000130164', 'SYP', 'Synaptophysin', 'X', 'protein_coding', 'Synaptic vesicle protein'),
('ENSG00000100604', 'CHGA', 'Chromogranin A', '14', 'protein_coding', 'Secretory granule protein'),
('ENSG00000100299', 'INS', 'Insulin', '11', 'protein_coding', 'Insulin hormone'),
('ENSG00000139618', 'TP53', 'Tumor protein p53', '17', 'protein_coding', 'Tumor suppressor protein'),
('ENSG00000141510', 'RB1', 'RB transcriptional corepressor 1', '13', 'protein_coding', 'Tumor suppressor protein');

-- 创建存储过程
DELIMITER //

-- 获取数据集统计信息
CREATE PROCEDURE GetDatasetStats(IN dataset_geo_id VARCHAR(20))
BEGIN
    SELECT 
        d.geo_id,
        d.title,
        d.tissue_type,
        d.tumor_type,
        d.n_samples,
        d.n_genes,
        COUNT(s.id) as actual_samples,
        COUNT(DISTINCT ge.gene_symbol) as unique_genes,
        AVG(ge.expression_value) as avg_expression,
        MAX(ge.expression_value) as max_expression,
        MIN(ge.expression_value) as min_expression
    FROM datasets d
    LEFT JOIN samples s ON d.id = s.dataset_id
    LEFT JOIN gene_expression ge ON d.id = ge.dataset_id
    WHERE d.geo_id = dataset_geo_id
    GROUP BY d.id;
END //

-- 获取基因表达数据
CREATE PROCEDURE GetGeneExpression(IN dataset_geo_id VARCHAR(20), IN gene_symbol VARCHAR(50))
BEGIN
    SELECT 
        ge.sample_id,
        ge.gene_symbol,
        ge.expression_value,
        ge.log2_expression,
        s.tumor_type,
        s.grade,
        s.stage,
        s.survival_status,
        s.survival_time
    FROM gene_expression ge
    JOIN datasets d ON ge.dataset_id = d.id
    LEFT JOIN samples s ON ge.sample_id = s.sample_id AND ge.dataset_id = s.dataset_id
    WHERE d.geo_id = dataset_geo_id 
    AND ge.gene_symbol = gene_symbol
    ORDER BY ge.expression_value DESC;
END //

DELIMITER ;

-- 创建触发器
-- 更新数据集统计信息
DELIMITER //
CREATE TRIGGER update_dataset_stats_after_insert
AFTER INSERT ON samples
FOR EACH ROW
BEGIN
    UPDATE datasets 
    SET n_samples = (
        SELECT COUNT(*) FROM samples WHERE dataset_id = NEW.dataset_id
    )
    WHERE id = NEW.dataset_id;
END //

CREATE TRIGGER update_dataset_stats_after_delete
AFTER DELETE ON samples
FOR EACH ROW
BEGIN
    UPDATE datasets 
    SET n_samples = (
        SELECT COUNT(*) FROM samples WHERE dataset_id = OLD.dataset_id
    )
    WHERE id = OLD.dataset_id;
END //
DELIMITER ;

-- 创建索引优化查询性能
CREATE INDEX idx_expression_composite ON gene_expression(dataset_id, gene_symbol, expression_value);
CREATE INDEX idx_samples_composite ON samples(dataset_id, tumor_type, grade, stage);
CREATE INDEX idx_de_composite ON differential_expression(dataset_id, gene_symbol, log2_fold_change, p_value);

-- 设置MySQL配置优化
SET GLOBAL innodb_buffer_pool_size = 1073741824; -- 1GB
SET GLOBAL max_connections = 200;
SET GLOBAL query_cache_size = 67108864; -- 64MB
SET GLOBAL query_cache_type = 1;

-- 显示创建完成信息
SELECT 'NETA数据库初始化完成！' as message;
SELECT '已创建的表:' as info;
SHOW TABLES;
SELECT '已创建的视图:' as info;
SHOW FULL TABLES WHERE Table_type = 'VIEW';
SELECT '已创建的存储过程:' as info;
SHOW PROCEDURE STATUS WHERE Db = 'neta_db';
