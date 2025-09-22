# NETA数据库架构设计
# MySQL后端 + 前端展示系统

## 系统架构

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   前端展示层     │    │   应用服务层     │    │   数据存储层     │
│                 │    │                 │    │                 │
│ • React/Vue.js  │◄──►│ • Node.js/Flask │◄──►│ • MySQL数据库   │
│ • Shiny App     │    │ • R Shiny       │    │ • Redis缓存     │
│ • Web界面       │    │ • API接口       │    │ • 文件存储      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 数据库设计

### 1. 核心表结构

#### 数据集表 (datasets)
```sql
CREATE TABLE datasets (
    id INT PRIMARY KEY AUTO_INCREMENT,
    geo_id VARCHAR(20) UNIQUE NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    tissue_type VARCHAR(100),
    tumor_type VARCHAR(100),
    platform VARCHAR(200),
    n_samples INT,
    n_genes INT,
    publication_year YEAR,
    reference_pmid VARCHAR(20),
    data_source VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

#### 样本信息表 (samples)
```sql
CREATE TABLE samples (
    id INT PRIMARY KEY AUTO_INCREMENT,
    dataset_id INT,
    sample_id VARCHAR(100) NOT NULL,
    sample_name VARCHAR(200),
    tissue_type VARCHAR(100),
    tumor_type VARCHAR(100),
    grade VARCHAR(10),
    stage VARCHAR(10),
    age INT,
    gender ENUM('Male', 'Female', 'Unknown'),
    survival_status ENUM('Alive', 'Dead', 'Unknown'),
    survival_time INT,
    treatment_type VARCHAR(200),
    FOREIGN KEY (dataset_id) REFERENCES datasets(id),
    INDEX idx_dataset_sample (dataset_id, sample_id)
);
```

#### 基因表达表 (gene_expression)
```sql
CREATE TABLE gene_expression (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    dataset_id INT,
    sample_id VARCHAR(100),
    gene_id VARCHAR(50),
    gene_symbol VARCHAR(50),
    expression_value DECIMAL(15,3),
    log2_fold_change DECIMAL(10,3),
    p_value DECIMAL(15,10),
    adjusted_p_value DECIMAL(15,10),
    FOREIGN KEY (dataset_id) REFERENCES datasets(id),
    INDEX idx_dataset_gene (dataset_id, gene_id),
    INDEX idx_sample_gene (sample_id, gene_id),
    INDEX idx_gene_symbol (gene_symbol)
);
```

#### 基因信息表 (genes)
```sql
CREATE TABLE genes (
    id INT PRIMARY KEY AUTO_INCREMENT,
    gene_id VARCHAR(50) UNIQUE NOT NULL,
    gene_symbol VARCHAR(50),
    gene_name TEXT,
    chromosome VARCHAR(10),
    start_position BIGINT,
    end_position BIGINT,
    gene_type VARCHAR(50),
    description TEXT,
    INDEX idx_symbol (gene_symbol),
    INDEX idx_chromosome (chromosome)
);
```

#### 通路信息表 (pathways)
```sql
CREATE TABLE pathways (
    id INT PRIMARY KEY AUTO_INCREMENT,
    pathway_id VARCHAR(50) UNIQUE NOT NULL,
    pathway_name VARCHAR(500),
    pathway_source VARCHAR(50),
    pathway_category VARCHAR(100),
    description TEXT,
    gene_count INT,
    INDEX idx_source (pathway_source),
    INDEX idx_category (pathway_category)
);
```

#### 通路基因关联表 (pathway_genes)
```sql
CREATE TABLE pathway_genes (
    id INT PRIMARY KEY AUTO_INCREMENT,
    pathway_id VARCHAR(50),
    gene_id VARCHAR(50),
    FOREIGN KEY (pathway_id) REFERENCES pathways(pathway_id),
    FOREIGN KEY (gene_id) REFERENCES genes(gene_id),
    INDEX idx_pathway (pathway_id),
    INDEX idx_gene (gene_id)
);
```

#### 分析结果表 (analysis_results)
```sql
CREATE TABLE analysis_results (
    id INT PRIMARY KEY AUTO_INCREMENT,
    dataset_id INT,
    analysis_type VARCHAR(50),
    comparison_group1 VARCHAR(200),
    comparison_group2 VARCHAR(200),
    result_summary TEXT,
    result_file_path VARCHAR(500),
    parameters JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (dataset_id) REFERENCES datasets(id),
    INDEX idx_dataset_type (dataset_id, analysis_type)
);
```

### 2. 索引优化

```sql
-- 复合索引优化查询性能
CREATE INDEX idx_expression_dataset_sample_gene ON gene_expression(dataset_id, sample_id, gene_id);
CREATE INDEX idx_samples_dataset_tumor ON samples(dataset_id, tumor_type);
CREATE INDEX idx_genes_symbol_type ON genes(gene_symbol, gene_type);
```

### 3. 视图定义

```sql
-- 数据集概览视图
CREATE VIEW dataset_overview AS
SELECT 
    d.geo_id,
    d.title,
    d.tissue_type,
    d.tumor_type,
    d.n_samples,
    d.n_genes,
    d.publication_year,
    COUNT(s.id) as actual_samples,
    COUNT(DISTINCT s.tumor_type) as tumor_subtypes
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
    MAX(ge.expression_value) as max_expression
FROM gene_expression ge
JOIN datasets d ON ge.dataset_id = d.id
GROUP BY d.geo_id, ge.gene_symbol;
```

## 后端API设计

### 1. 数据集API

```python
# Flask API示例
from flask import Flask, jsonify, request
from flask_sqlalchemy import SQLAlchemy
import pandas as pd

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'mysql://user:password@localhost/neta_db'
db = SQLAlchemy(app)

@app.route('/api/datasets', methods=['GET'])
def get_datasets():
    """获取所有数据集列表"""
    datasets = db.session.query(Dataset).all()
    return jsonify([{
        'id': d.id,
        'geo_id': d.geo_id,
        'title': d.title,
        'tissue_type': d.tissue_type,
        'tumor_type': d.tumor_type,
        'n_samples': d.n_samples,
        'n_genes': d.n_genes,
        'publication_year': d.publication_year
    } for d in datasets])

@app.route('/api/datasets/<geo_id>/samples', methods=['GET'])
def get_dataset_samples(geo_id):
    """获取特定数据集的样本信息"""
    samples = db.session.query(Sample).join(Dataset).filter(Dataset.geo_id == geo_id).all()
    return jsonify([{
        'sample_id': s.sample_id,
        'sample_name': s.sample_name,
        'tissue_type': s.tissue_type,
        'tumor_type': s.tumor_type,
        'grade': s.grade,
        'stage': s.stage,
        'age': s.age,
        'gender': s.gender
    } for s in samples])

@app.route('/api/datasets/<geo_id>/expression', methods=['GET'])
def get_gene_expression(geo_id):
    """获取基因表达数据"""
    gene_symbol = request.args.get('gene_symbol')
    sample_ids = request.args.getlist('sample_ids')
    
    query = db.session.query(GeneExpression).join(Dataset).filter(Dataset.geo_id == geo_id)
    
    if gene_symbol:
        query = query.filter(GeneExpression.gene_symbol == gene_symbol)
    if sample_ids:
        query = query.filter(GeneExpression.sample_id.in_(sample_ids))
    
    expressions = query.all()
    return jsonify([{
        'sample_id': e.sample_id,
        'gene_symbol': e.gene_symbol,
        'expression_value': float(e.expression_value),
        'log2_fold_change': float(e.log2_fold_change) if e.log2_fold_change else None
    } for e in expressions])
```

### 2. 分析API

```python
@app.route('/api/analysis/differential_expression', methods=['POST'])
def run_differential_expression():
    """运行差异表达分析"""
    data = request.json
    dataset_id = data['dataset_id']
    group1 = data['group1']
    group2 = data['group2']
    
    # 调用R脚本进行差异表达分析
    result = run_r_script('differential_expression.R', {
        'dataset_id': dataset_id,
        'group1': group1,
        'group2': group2
    })
    
    # 保存结果到数据库
    analysis_result = AnalysisResult(
        dataset_id=dataset_id,
        analysis_type='differential_expression',
        comparison_group1=group1,
        comparison_group2=group2,
        result_summary=result['summary'],
        parameters=json.dumps(data)
    )
    db.session.add(analysis_result)
    db.session.commit()
    
    return jsonify({'status': 'success', 'result_id': analysis_result.id})

@app.route('/api/analysis/survival', methods=['POST'])
def run_survival_analysis():
    """运行生存分析"""
    data = request.json
    dataset_id = data['dataset_id']
    gene_symbol = data['gene_symbol']
    
    # 调用R脚本进行生存分析
    result = run_r_script('survival_analysis.R', {
        'dataset_id': dataset_id,
        'gene_symbol': gene_symbol
    })
    
    return jsonify({'status': 'success', 'result': result})
```

## 前端设计

### 1. React前端组件

```jsx
// DatasetList.jsx
import React, { useState, useEffect } from 'react';
import axios from 'axios';

const DatasetList = () => {
    const [datasets, setDatasets] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        fetchDatasets();
    }, []);

    const fetchDatasets = async () => {
        try {
            const response = await axios.get('/api/datasets');
            setDatasets(response.data);
        } catch (error) {
            console.error('Error fetching datasets:', error);
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="dataset-list">
            <h2>神经内分泌肿瘤数据集</h2>
            {loading ? (
                <div>加载中...</div>
            ) : (
                <div className="datasets-grid">
                    {datasets.map(dataset => (
                        <div key={dataset.id} className="dataset-card">
                            <h3>{dataset.title}</h3>
                            <p>GEO ID: {dataset.geo_id}</p>
                            <p>组织类型: {dataset.tissue_type}</p>
                            <p>肿瘤类型: {dataset.tumor_type}</p>
                            <p>样本数: {dataset.n_samples}</p>
                            <p>基因数: {dataset.n_genes}</p>
                            <button onClick={() => viewDataset(dataset.geo_id)}>
                                查看详情
                            </button>
                        </div>
                    ))}
                </div>
            )}
        </div>
    );
};

export default DatasetList;
```

### 2. 基因表达可视化组件

```jsx
// GeneExpressionChart.jsx
import React, { useState, useEffect } from 'react';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend } from 'recharts';
import axios from 'axios';

const GeneExpressionChart = ({ datasetId, geneSymbol }) => {
    const [data, setData] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        if (datasetId && geneSymbol) {
            fetchExpressionData();
        }
    }, [datasetId, geneSymbol]);

    const fetchExpressionData = async () => {
        try {
            const response = await axios.get(`/api/datasets/${datasetId}/expression`, {
                params: { gene_symbol: geneSymbol }
            });
            setData(response.data);
        } catch (error) {
            console.error('Error fetching expression data:', error);
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="gene-expression-chart">
            <h3>基因表达分析: {geneSymbol}</h3>
            {loading ? (
                <div>加载中...</div>
            ) : (
                <LineChart width={800} height={400} data={data}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="sample_id" />
                    <YAxis />
                    <Tooltip />
                    <Legend />
                    <Line type="monotone" dataKey="expression_value" stroke="#8884d8" />
                </LineChart>
            )}
        </div>
    );
};

export default GeneExpressionChart;
```

## 部署配置

### 1. Docker配置

```dockerfile
# Dockerfile
FROM python:3.9-slim

WORKDIR /app

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    mysql-client \
    r-base \
    && rm -rf /var/lib/apt/lists/*

# 安装Python依赖
COPY requirements.txt .
RUN pip install -r requirements.txt

# 安装R包
RUN Rscript -e "install.packages(c('GEOquery', 'dplyr', 'ggplot2'), repos='https://cran.rstudio.com/')"

# 复制应用代码
COPY . .

EXPOSE 5000

CMD ["python", "app.py"]
```

### 2. Docker Compose配置

```yaml
# docker-compose.yml
version: '3.8'

services:
  mysql:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: rootpassword
      MYSQL_DATABASE: neta_db
      MYSQL_USER: neta_user
      MYSQL_PASSWORD: neta_password
    volumes:
      - mysql_data:/var/lib/mysql
    ports:
      - "3306:3306"

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  backend:
    build: .
    environment:
      DATABASE_URL: mysql://neta_user:neta_password@mysql:3306/neta_db
      REDIS_URL: redis://redis:6379
    ports:
      - "5000:5000"
    depends_on:
      - mysql
      - redis

  frontend:
    build: ./frontend
    ports:
      - "3000:3000"
    depends_on:
      - backend

volumes:
  mysql_data:
```

## 数据导入脚本

```python
# data_import.py
import pandas as pd
import pymysql
from sqlalchemy import create_engine

def import_dataset_to_mysql(geo_id, expression_file, metadata_file):
    """将数据集导入MySQL数据库"""
    
    # 连接数据库
    engine = create_engine('mysql://user:password@localhost/neta_db')
    
    # 读取数据
    expression_df = pd.read_csv(expression_file)
    metadata_df = pd.read_csv(metadata_file)
    
    # 导入数据集信息
    dataset_info = {
        'geo_id': geo_id,
        'title': f'Dataset {geo_id}',
        'n_samples': len(metadata_df),
        'n_genes': len(expression_df)
    }
    
    # 导入样本信息
    metadata_df['dataset_id'] = 1  # 假设数据集ID为1
    metadata_df.to_sql('samples', engine, if_exists='append', index=False)
    
    # 导入基因表达数据
    expression_melted = pd.melt(expression_df, 
                               id_vars=['gene_id', 'gene_symbol'],
                               var_name='sample_id',
                               value_name='expression_value')
    expression_melted['dataset_id'] = 1
    expression_melted.to_sql('gene_expression', engine, if_exists='append', index=False)
    
    print(f"数据集 {geo_id} 导入完成")

if __name__ == "__main__":
    import_dataset_to_mysql('GSE73338', 'data/raw/GSE73338_expression.csv', 'data/raw/GSE73338_phenotype.csv')
```

这个MySQL + 前端的架构设计提供了：

1. **专业数据库管理** - 结构化存储，支持复杂查询
2. **RESTful API** - 标准化的数据接口
3. **现代前端** - React/Vue.js交互界面
4. **可扩展性** - 支持大规模数据和高并发访问
5. **数据完整性** - 外键约束和数据验证

您觉得这个架构设计如何？需要我详细实现某个部分吗？
