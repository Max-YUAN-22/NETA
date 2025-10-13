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
    # 仅返回存在基因表达数据的数据集，保证学术严谨性
    exists_expr = db.session.query(GeneExpression.id).filter(GeneExpression.dataset_id == Dataset.id).exists()
    datasets = Dataset.query.filter(exists_expr).paginate(
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
    # 若该数据集没有表达数据，则不返回详情
    has_expr = db.session.query(GeneExpression.id).filter(GeneExpression.dataset_id == dataset.id).first()
    if not has_expr:
        return jsonify({'error': 'Dataset has no expression data'}), 404
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
    
    # 按数据源统计
    source_stats = db.session.query(
        Dataset.data_source, db.func.count(Dataset.id)
    ).group_by(Dataset.data_source).all()
    
    # 按发表年份统计
    year_stats = db.session.query(
        Dataset.publication_year, db.func.count(Dataset.id)
    ).group_by(Dataset.publication_year).all()
    
    # 按优先级统计
    priority_stats = db.session.query(
        Dataset.priority, db.func.count(Dataset.id)
    ).group_by(Dataset.priority).all()
    
    # 表达数据统计
    expr_stats = db.session.query(
        db.func.min(GeneExpression.expression_value).label('min_value'),
        db.func.max(GeneExpression.expression_value).label('max_value'),
        db.func.avg(GeneExpression.expression_value).label('mean_value'),
        db.func.count(GeneExpression.id).label('total_records'),
        db.func.sum(db.case([(GeneExpression.expression_value > 0, 1)], else_=0)).label('non_zero_records')
    ).first()
    
    # 计算数据质量评分
    completeness_score = min(100, (total_datasets * 10 + total_samples * 0.1 + total_genes * 0.01))
    coverage_score = (expr_stats.non_zero_records / expr_stats.total_records * 100) if expr_stats.total_records > 0 else 0
    diversity_score = min(100, len(tissue_stats) * 20 + len(tumor_stats) * 10)
    overall_score = (completeness_score + coverage_score + diversity_score) / 3
    
    return jsonify({
        'total_datasets': total_datasets,
        'total_samples': total_samples,
        'total_genes': total_genes,
        'total_expressions': total_expressions,
        'tissue_types': [{'name': t[0], 'count': t[1]} for t in tissue_stats],
        'tumor_types': [{'name': t[0], 'count': t[1]} for t in tumor_stats],
        'data_sources': [{'name': s[0], 'count': s[1]} for s in source_stats],
        'publication_years': [{'name': str(y[0]), 'count': y[1]} for y in year_stats if y[0]],
        'priority_levels': [{'name': f'Priority {p[0]}', 'count': p[1]} for p in priority_stats],
        'expression_statistics': {
            'min_value': float(expr_stats.min_value) if expr_stats.min_value else 0,
            'max_value': float(expr_stats.max_value) if expr_stats.max_value else 0,
            'mean_value': float(expr_stats.mean_value) if expr_stats.mean_value else 0,
            'total_records': expr_stats.total_records,
            'non_zero_records': expr_stats.non_zero_records
        },
        'quality_metrics': {
            'data_completeness': round(completeness_score, 2),
            'expression_coverage': round(coverage_score, 2),
            'dataset_diversity': round(diversity_score, 2),
            'overall_score': round(overall_score, 2)
        }
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

@app.route('/api/datasets/filter', methods=['GET'])
def filter_datasets():
    tissue_type = request.args.get('tissue_type', '')
    tumor_type = request.args.get('tumor_type', '')
    data_source = request.args.get('data_source', '')
    priority = request.args.get('priority', type=int)
    min_samples = request.args.get('min_samples', type=int)
    max_samples = request.args.get('max_samples', type=int)
    min_genes = request.args.get('min_genes', type=int)
    max_genes = request.args.get('max_genes', type=int)
    year_from = request.args.get('year_from', type=int)
    year_to = request.args.get('year_to', type=int)
    
    # 仅返回存在表达数据的数据集
    exists_expr = db.session.query(GeneExpression.id).filter(GeneExpression.dataset_id == Dataset.id).exists()
    query = Dataset.query.filter(exists_expr)
    
    if tissue_type:
        query = query.filter(Dataset.tissue_type == tissue_type)
    if tumor_type:
        query = query.filter(Dataset.tumor_type == tumor_type)
    if data_source:
        query = query.filter(Dataset.data_source == data_source)
    if priority:
        query = query.filter(Dataset.priority == priority)
    if min_samples:
        query = query.filter(Dataset.n_samples >= min_samples)
    if max_samples:
        query = query.filter(Dataset.n_samples <= max_samples)
    if min_genes:
        query = query.filter(Dataset.n_genes >= min_genes)
    if max_genes:
        query = query.filter(Dataset.n_genes <= max_genes)
    if year_from:
        query = query.filter(Dataset.publication_year >= year_from)
    if year_to:
        query = query.filter(Dataset.publication_year <= year_to)
    
    datasets = query.all()
    
    return jsonify([{
        'id': d.id,
        'geo_id': d.geo_id,
        'title': d.title,
        'tissue_type': d.tissue_type,
        'tumor_type': d.tumor_type,
        'data_source': d.data_source,
        'n_samples': d.n_samples,
        'n_genes': d.n_genes,
        'publication_year': d.publication_year,
        'priority': d.priority
    } for d in datasets])

@app.route('/api/datasets/search', methods=['GET'])
def search_datasets():
    query = request.args.get('q', '')
    limit = request.args.get('limit', 20, type=int)
    # 仅返回存在表达数据的数据集
    exists_expr = db.session.query(GeneExpression.id).filter(GeneExpression.dataset_id == Dataset.id).exists()
    datasets = Dataset.query.filter(exists_expr).filter(
        Dataset.title.contains(query) | 
        Dataset.description.contains(query) |
        Dataset.geo_id.contains(query)
    ).limit(limit).all()
    
    return jsonify([{
        'id': d.id,
        'geo_id': d.geo_id,
        'title': d.title,
        'tissue_type': d.tissue_type,
        'tumor_type': d.tumor_type,
        'data_source': d.data_source,
        'n_samples': d.n_samples,
        'n_genes': d.n_genes,
        'publication_year': d.publication_year,
        'priority': d.priority
    } for d in datasets])

@app.route('/api/datasets/statistics', methods=['GET'])
def get_dataset_statistics():
    # 按数据源统计
    source_stats = db.session.query(
        Dataset.data_source, db.func.count(Dataset.id)
    ).group_by(Dataset.data_source).all()
    
    # 按优先级统计
    priority_stats = db.session.query(
        Dataset.priority, db.func.count(Dataset.id)
    ).group_by(Dataset.priority).all()
    
    # 按组织类型统计
    tissue_stats = db.session.query(
        Dataset.tissue_type, db.func.count(Dataset.id)
    ).group_by(Dataset.tissue_type).all()
    
    # 按肿瘤类型统计
    tumor_stats = db.session.query(
        Dataset.tumor_type, db.func.count(Dataset.id)
    ).group_by(Dataset.tumor_type).all()
    
    # 样本数分布
    sample_dist = db.session.query(
        db.case([
            (Dataset.n_samples < 50, 'Small (<50)'),
            (Dataset.n_samples < 100, 'Medium (50-100)'),
            (Dataset.n_samples < 200, 'Large (100-200)'),
            (Dataset.n_samples < 500, 'Very Large (200-500)')
        ], else_='Huge (500+)').label('size_category'),
        db.func.count(Dataset.id)
    ).group_by('size_category').all()
    
    return jsonify({
        'data_sources': [{'name': s[0], 'count': s[1]} for s in source_stats],
        'priority_levels': [{'name': f'Priority {p[0]}', 'count': p[1]} for p in priority_stats],
        'tissue_types': [{'name': t[0], 'count': t[1]} for t in tissue_stats],
        'tumor_types': [{'name': t[0], 'count': t[1]} for t in tumor_stats],
        'sample_sizes': [{'name': s[0], 'count': s[1]} for s in sample_dist]
    })

@app.route('/api/analysis/batch', methods=['POST'])
def run_batch_analysis():
    data = request.get_json()
    analysis_type = data.get('analysis_type')
    dataset_ids = data.get('dataset_ids', [])
    parameters = data.get('parameters', {})
    
    if not dataset_ids:
        return jsonify({'error': 'No datasets specified'}), 400
    
    results = []
    for dataset_id in dataset_ids:
        try:
            # 创建分析任务
            task = AnalysisTask(
                task_type=analysis_type,
                dataset_id=dataset_id,
                parameters=json.dumps(parameters),
                status='running'
            )
            db.session.add(task)
            db.session.commit()
            
            # 运行分析
            result = r_runner.run_analysis(analysis_type, {
                'dataset_id': dataset_id,
                **parameters
            })
            
            # 更新任务状态
            task.status = 'completed'
            task.results = json.dumps(result)
            task.completed_at = datetime.utcnow()
            db.session.commit()
            
            results.append({
                'dataset_id': dataset_id,
                'task_id': task.id,
                'status': 'completed',
                'results': result
            })
        except Exception as e:
            if 'task' in locals():
                task.status = 'failed'
                task.results = json.dumps({'error': str(e)})
                db.session.commit()
            
            results.append({
                'dataset_id': dataset_id,
                'status': 'failed',
                'error': str(e)
            })
    
    return jsonify({
        'analysis_type': analysis_type,
        'total_datasets': len(dataset_ids),
        'successful': len([r for r in results if r['status'] == 'completed']),
        'failed': len([r for r in results if r['status'] == 'failed']),
        'results': results
    })

if __name__ == '__main__':
    # 创建数据库表
    with app.app_context():
        db.create_all()

    # 部署环境通常提供 PORT 环境变量（如 Render/Heroku）
    port = int(os.environ.get('PORT', '5000'))

    # 启动应用
    app.run(host='0.0.0.0', port=port, debug=os.environ.get('FLASK_DEBUG','false').lower()=='true')
