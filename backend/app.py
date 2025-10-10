#!/usr/bin/env python3
# NETA Backend - 泛神经内分泌癌转录组学分析平台后端

from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from flask_cors import CORS
import os
import json
from datetime import datetime
from r_runner import RRunner

# 创建Flask应用
app = Flask(__name__)
CORS(app)

# 数据库配置
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///neta_data.sqlite'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

# 初始化数据库
db = SQLAlchemy(app)

# 数据库模型
class Dataset(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    geo_id = db.Column(db.String(50), unique=True, nullable=False)
    title = db.Column(db.String(500))
    description = db.Column(db.Text)
    tissue_type = db.Column(db.String(100))
    tumor_type = db.Column(db.String(100))
    platform = db.Column(db.String(100))
    n_samples = db.Column(db.Integer)
    n_genes = db.Column(db.Integer)
    publication_year = db.Column(db.Integer)
    reference_pmid = db.Column(db.String(50))
    data_source = db.Column(db.String(50))
    status = db.Column(db.String(20), default='active')
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

class Sample(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    dataset_id = db.Column(db.Integer, db.ForeignKey('dataset.id'))
    sample_id = db.Column(db.String(100))
    sample_name = db.Column(db.String(200))
    tissue_type = db.Column(db.String(100))
    tumor_type = db.Column(db.String(100))
    tumor_subtype = db.Column(db.String(100))
    grade = db.Column(db.String(50))
    stage = db.Column(db.String(50))
    age = db.Column(db.Integer)
    gender = db.Column(db.String(20))
    survival_status = db.Column(db.String(50))
    survival_time = db.Column(db.Integer)
    treatment_type = db.Column(db.String(100))
    metastasis_status = db.Column(db.String(50))
    primary_site = db.Column(db.String(100))
    quality_score = db.Column(db.Float)

class Gene(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    gene_id = db.Column(db.String(100), unique=True, nullable=False)
    gene_symbol = db.Column(db.String(100))
    gene_name = db.Column(db.String(200))
    chromosome = db.Column(db.String(10))
    gene_type = db.Column(db.String(50))
    description = db.Column(db.Text)
    entrez_id = db.Column(db.String(50))
    ensembl_id = db.Column(db.String(100))

class GeneExpression(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    dataset_id = db.Column(db.Integer, db.ForeignKey('dataset.id'))
    sample_id = db.Column(db.String(100))
    gene_id = db.Column(db.String(100))
    gene_symbol = db.Column(db.String(100))
    expression_value = db.Column(db.Float)
    log2_expression = db.Column(db.Float)
    normalized_value = db.Column(db.Float)
    percentile_rank = db.Column(db.Float)
    is_expressed = db.Column(db.Boolean)

class AnalysisTask(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    task_type = db.Column(db.String(50))
    dataset_id = db.Column(db.Integer, db.ForeignKey('dataset.id'))
    parameters = db.Column(db.Text)
    status = db.Column(db.String(20), default='pending')
    results = db.Column(db.Text)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    completed_at = db.Column(db.DateTime)

# 初始化R运行器
r_runner = RRunner()

# API路由
@app.route('/api/health', methods=['GET'])
def health_check():
    return jsonify({
        'status': 'healthy',
        'message': 'NETA API is running',
        'timestamp': datetime.utcnow().isoformat()
    })

@app.route('/api/datasets', methods=['GET'])
def get_datasets():
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 20, type=int)
    
    datasets = Dataset.query.paginate(
        page=page, per_page=per_page, error_out=False
    )
    
    return jsonify({
        'datasets': [{
            'id': d.id,
            'geo_id': d.geo_id,
            'title': d.title,
            'tissue_type': d.tissue_type,
            'tumor_type': d.tumor_type,
            'n_samples': d.n_samples,
            'n_genes': d.n_genes,
            'publication_year': d.publication_year
        } for d in datasets.items],
        'total': datasets.total,
        'pages': datasets.pages,
        'current_page': page
    })

@app.route('/api/datasets/<int:dataset_id>', methods=['GET'])
def get_dataset_detail(dataset_id):
    dataset = Dataset.query.get_or_404(dataset_id)
    return jsonify({
        'id': dataset.id,
        'geo_id': dataset.geo_id,
        'title': dataset.title,
        'description': dataset.description,
        'tissue_type': dataset.tissue_type,
        'tumor_type': dataset.tumor_type,
        'platform': dataset.platform,
        'n_samples': dataset.n_samples,
        'n_genes': dataset.n_genes,
        'publication_year': dataset.publication_year,
        'reference_pmid': dataset.reference_pmid,
        'data_source': dataset.data_source
    })

@app.route('/api/statistics/overview', methods=['GET'])
def get_statistics():
    total_datasets = Dataset.query.count()
    total_samples = Sample.query.count()
    total_genes = Gene.query.count()
    total_expressions = GeneExpression.query.count()
    
    # 按组织类型统计
    tissue_stats = db.session.query(
        Dataset.tissue_type, db.func.count(Dataset.id)
    ).group_by(Dataset.tissue_type).all()
    
    # 按肿瘤类型统计
    tumor_stats = db.session.query(
        Dataset.tumor_type, db.func.count(Dataset.id)
    ).group_by(Dataset.tumor_type).all()
    
    # 按发表年份统计
    year_stats = db.session.query(
        Dataset.publication_year, db.func.count(Dataset.id)
    ).group_by(Dataset.publication_year).all()
    
    return jsonify({
        'total_datasets': total_datasets,
        'total_samples': total_samples,
        'total_genes': total_genes,
        'total_expressions': total_expressions,
        'tissue_types': [{'name': t[0], 'count': t[1]} for t in tissue_stats],
        'tumor_types': [{'name': t[0], 'count': t[1]} for t in tumor_stats],
        'publication_years': [{'name': str(y[0]), 'count': y[1]} for y in year_stats if y[0]]
    })

@app.route('/api/analysis/differential_expression', methods=['POST'])
def run_differential_expression():
    data = request.get_json()
    
    # 创建分析任务
    task = AnalysisTask(
        task_type='differential_expression',
        dataset_id=data.get('dataset_id'),
        parameters=json.dumps(data),
        status='running'
    )
    db.session.add(task)
    db.session.commit()
    
    try:
        # 运行R分析
        result = r_runner.run_analysis('differential_expression', data)
        
        # 更新任务状态
        task.status = 'completed'
        task.results = json.dumps(result)
        task.completed_at = datetime.utcnow()
        db.session.commit()
        
        return jsonify({
            'task_id': task.id,
            'status': 'completed',
            'results': result
        })
    except Exception as e:
        task.status = 'failed'
        task.results = json.dumps({'error': str(e)})
        db.session.commit()
        
        return jsonify({
            'task_id': task.id,
            'status': 'failed',
            'error': str(e)
        }), 500

@app.route('/api/analysis/pca', methods=['POST'])
def run_pca_analysis():
    data = request.get_json()
    
    task = AnalysisTask(
        task_type='pca',
        dataset_id=data.get('dataset_id'),
        parameters=json.dumps(data),
        status='running'
    )
    db.session.add(task)
    db.session.commit()
    
    try:
        result = r_runner.run_analysis('pca_analysis', data)
        
        task.status = 'completed'
        task.results = json.dumps(result)
        task.completed_at = datetime.utcnow()
        db.session.commit()
        
        return jsonify({
            'task_id': task.id,
            'status': 'completed',
            'results': result
        })
    except Exception as e:
        task.status = 'failed'
        task.results = json.dumps({'error': str(e)})
        db.session.commit()
        
        return jsonify({
            'task_id': task.id,
            'status': 'failed',
            'error': str(e)
        }), 500

@app.route('/api/analysis/enrichment', methods=['POST'])
def run_enrichment_analysis():
    data = request.get_json()
    
    task = AnalysisTask(
        task_type='enrichment',
        dataset_id=data.get('dataset_id'),
        parameters=json.dumps(data),
        status='running'
    )
    db.session.add(task)
    db.session.commit()
    
    try:
        result = r_runner.run_analysis('enrichment_analysis', data)
        
        task.status = 'completed'
        task.results = json.dumps(result)
        task.completed_at = datetime.utcnow()
        db.session.commit()
        
        return jsonify({
            'task_id': task.id,
            'status': 'completed',
            'results': result
        })
    except Exception as e:
        task.status = 'failed'
        task.results = json.dumps({'error': str(e)})
        db.session.commit()
        
        return jsonify({
            'task_id': task.id,
            'status': 'failed',
            'error': str(e)
        }), 500

@app.route('/api/genes/search', methods=['GET'])
def search_genes():
    query = request.args.get('q', '')
    limit = request.args.get('limit', 50, type=int)
    
    genes = Gene.query.filter(
        Gene.gene_symbol.contains(query) | 
        Gene.gene_name.contains(query)
    ).limit(limit).all()
    
    return jsonify([{
        'id': g.id,
        'gene_id': g.gene_id,
        'gene_symbol': g.gene_symbol,
        'gene_name': g.gene_name,
        'chromosome': g.chromosome,
        'gene_type': g.gene_type
    } for g in genes])

if __name__ == '__main__':
    # 创建数据库表
    with app.app_context():
        db.create_all()
    
    # 启动应用
    app.run(host='0.0.0.0', port=5000, debug=True)
