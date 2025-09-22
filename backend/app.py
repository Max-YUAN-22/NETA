# NETA后端API服务
# Flask + SQLAlchemy + MySQL

from flask import Flask, jsonify, request, send_file
from flask_sqlalchemy import SQLAlchemy
from flask_cors import CORS
from flask_jwt_extended import JWTManager, jwt_required, create_access_token, get_jwt_identity
from werkzeug.security import generate_password_hash, check_password_hash
import pandas as pd
import numpy as np
import json
import os
from datetime import datetime, timedelta
import subprocess
import logging
from sqlalchemy import text, func, and_, or_
from sqlalchemy.dialects.mysql import insert

# 配置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# 创建Flask应用
app = Flask(__name__)
app.config['SECRET_KEY'] = 'neta-secret-key-2024'
app.config['SQLALCHEMY_DATABASE_URI'] = 'mysql://neta_user:neta_password@localhost/neta_db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['JWT_SECRET_KEY'] = 'jwt-secret-string'
app.config['JWT_ACCESS_TOKEN_EXPIRES'] = timedelta(hours=24)

# 初始化扩展
db = SQLAlchemy(app)
jwt = JWTManager(app)
CORS(app)

# 数据库模型定义
class Dataset(db.Model):
    __tablename__ = 'datasets'
    
    id = db.Column(db.Integer, primary_key=True)
    geo_id = db.Column(db.String(20), unique=True, nullable=False)
    title = db.Column(db.Text, nullable=False)
    description = db.Column(db.Text)
    tissue_type = db.Column(db.String(100))
    tumor_type = db.Column(db.String(100))
    platform = db.Column(db.String(200))
    n_samples = db.Column(db.Integer)
    n_genes = db.Column(db.Integer)
    publication_year = db.Column(db.Integer)
    reference_pmid = db.Column(db.String(20))
    data_source = db.Column(db.String(50), default='GEO')
    file_path = db.Column(db.String(500))
    status = db.Column(db.Enum('active', 'inactive', 'processing'), default='active')
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # 关系
    samples = db.relationship('Sample', backref='dataset', lazy=True, cascade='all, delete-orphan')
    gene_expressions = db.relationship('GeneExpression', backref='dataset', lazy=True, cascade='all, delete-orphan')

class Sample(db.Model):
    __tablename__ = 'samples'
    
    id = db.Column(db.Integer, primary_key=True)
    dataset_id = db.Column(db.Integer, db.ForeignKey('datasets.id'), nullable=False)
    sample_id = db.Column(db.String(100), nullable=False)
    sample_name = db.Column(db.String(200))
    tissue_type = db.Column(db.String(100))
    tumor_type = db.Column(db.String(100))
    tumor_subtype = db.Column(db.String(100))
    grade = db.Column(db.String(10))
    stage = db.Column(db.String(10))
    age = db.Column(db.Integer)
    gender = db.Column(db.Enum('Male', 'Female', 'Unknown'))
    survival_status = db.Column(db.Enum('Alive', 'Dead', 'Unknown'))
    survival_time = db.Column(db.Integer)
    treatment_type = db.Column(db.String(200))
    treatment_response = db.Column(db.String(100))
    metastasis_status = db.Column(db.Enum('Yes', 'No', 'Unknown'))
    primary_site = db.Column(db.String(100))
    sample_source = db.Column(db.String(100))
    collection_date = db.Column(db.Date)
    storage_method = db.Column(db.String(100))
    quality_score = db.Column(db.Numeric(3, 2))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class Gene(db.Model):
    __tablename__ = 'genes'
    
    id = db.Column(db.Integer, primary_key=True)
    gene_id = db.Column(db.String(50), unique=True, nullable=False)
    gene_symbol = db.Column(db.String(50))
    gene_name = db.Column(db.Text)
    chromosome = db.Column(db.String(10))
    start_position = db.Column(db.BigInteger)
    end_position = db.Column(db.BigInteger)
    strand = db.Column(db.Enum('+', '-', '?'))
    gene_type = db.Column(db.String(50))
    description = db.Column(db.Text)
    aliases = db.Column(db.Text)
    entrez_id = db.Column(db.String(20))
    ensembl_id = db.Column(db.String(50))
    uniprot_id = db.Column(db.String(20))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class GeneExpression(db.Model):
    __tablename__ = 'gene_expression'
    
    id = db.Column(db.BigInteger, primary_key=True)
    dataset_id = db.Column(db.Integer, db.ForeignKey('datasets.id'), nullable=False)
    sample_id = db.Column(db.String(100), nullable=False)
    gene_id = db.Column(db.String(50), db.ForeignKey('genes.gene_id'), nullable=False)
    gene_symbol = db.Column(db.String(50))
    expression_value = db.Column(db.Numeric(15, 3))
    log2_expression = db.Column(db.Numeric(10, 3))
    normalized_value = db.Column(db.Numeric(15, 3))
    percentile_rank = db.Column(db.Numeric(5, 2))
    is_expressed = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

class DifferentialExpression(db.Model):
    __tablename__ = 'differential_expression'
    
    id = db.Column(db.BigInteger, primary_key=True)
    dataset_id = db.Column(db.Integer, db.ForeignKey('datasets.id'), nullable=False)
    gene_id = db.Column(db.String(50), db.ForeignKey('genes.gene_id'), nullable=False)
    gene_symbol = db.Column(db.String(50))
    comparison_group1 = db.Column(db.String(200))
    comparison_group2 = db.Column(db.String(200))
    log2_fold_change = db.Column(db.Numeric(10, 3))
    fold_change = db.Column(db.Numeric(10, 3))
    p_value = db.Column(db.Numeric(15, 10))
    adjusted_p_value = db.Column(db.Numeric(15, 10))
    q_value = db.Column(db.Numeric(15, 10))
    base_mean = db.Column(db.Numeric(15, 3))
    lfc_se = db.Column(db.Numeric(10, 3))
    stat = db.Column(db.Numeric(10, 3))
    significance_level = db.Column(db.Enum('highly_significant', 'significant', 'not_significant'))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

class Pathway(db.Model):
    __tablename__ = 'pathways'
    
    id = db.Column(db.Integer, primary_key=True)
    pathway_id = db.Column(db.String(50), unique=True, nullable=False)
    pathway_name = db.Column(db.String(500))
    pathway_source = db.Column(db.String(50))
    pathway_category = db.Column(db.String(100))
    description = db.Column(db.Text)
    gene_count = db.Column(db.Integer)
    url = db.Column(db.String(500))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class PathwayGene(db.Model):
    __tablename__ = 'pathway_genes'
    
    id = db.Column(db.Integer, primary_key=True)
    pathway_id = db.Column(db.String(50), db.ForeignKey('pathways.pathway_id'), nullable=False)
    gene_id = db.Column(db.String(50), db.ForeignKey('genes.gene_id'), nullable=False)
    gene_symbol = db.Column(db.String(50))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

class AnalysisTask(db.Model):
    __tablename__ = 'analysis_tasks'
    
    id = db.Column(db.Integer, primary_key=True)
    dataset_id = db.Column(db.Integer, db.ForeignKey('datasets.id'), nullable=False)
    task_type = db.Column(db.String(50), nullable=False)
    task_name = db.Column(db.String(200))
    parameters = db.Column(db.JSON)
    status = db.Column(db.Enum('pending', 'running', 'completed', 'failed'), default='pending')
    progress = db.Column(db.Integer, default=0)
    result_summary = db.Column(db.Text)
    error_message = db.Column(db.Text)
    result_file_path = db.Column(db.String(500))
    started_at = db.Column(db.DateTime)
    completed_at = db.Column(db.DateTime)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

# API路由定义

# 1. 数据集相关API
@app.route('/api/datasets', methods=['GET'])
def get_datasets():
    """获取所有数据集列表"""
    try:
        page = request.args.get('page', 1, type=int)
        per_page = request.args.get('per_page', 10, type=int)
        tissue_type = request.args.get('tissue_type')
        tumor_type = request.args.get('tumor_type')
        
        query = Dataset.query
        
        if tissue_type:
            query = query.filter(Dataset.tissue_type == tissue_type)
        if tumor_type:
            query = query.filter(Dataset.tumor_type == tumor_type)
        
        datasets = query.paginate(
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
                'publication_year': d.publication_year,
                'reference_pmid': d.reference_pmid,
                'status': d.status,
                'created_at': d.created_at.isoformat()
            } for d in datasets.items],
            'total': datasets.total,
            'pages': datasets.pages,
            'current_page': page
        })
    except Exception as e:
        logger.error(f"Error getting datasets: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/datasets/<geo_id>', methods=['GET'])
def get_dataset_detail(geo_id):
    """获取特定数据集详细信息"""
    try:
        dataset = Dataset.query.filter_by(geo_id=geo_id).first()
        if not dataset:
            return jsonify({'error': 'Dataset not found'}), 404
        
        # 获取样本统计信息
        sample_stats = db.session.query(
            func.count(Sample.id).label('total_samples'),
            func.count(func.distinct(Sample.tumor_subtype)).label('tumor_subtypes'),
            func.count(func.distinct(Sample.grade)).label('grades'),
            func.count(func.distinct(Sample.stage)).label('stages'),
            func.avg(Sample.age).label('avg_age'),
            func.count(func.distinct(Sample.gender)).label('genders')
        ).filter(Sample.dataset_id == dataset.id).first()
        
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
            'status': dataset.status,
            'sample_stats': {
                'total_samples': sample_stats.total_samples,
                'tumor_subtypes': sample_stats.tumor_subtypes,
                'grades': sample_stats.grades,
                'stages': sample_stats.stages,
                'avg_age': float(sample_stats.avg_age) if sample_stats.avg_age else None,
                'genders': sample_stats.genders
            },
            'created_at': dataset.created_at.isoformat()
        })
    except Exception as e:
        logger.error(f"Error getting dataset detail: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/datasets/<geo_id>/samples', methods=['GET'])
def get_dataset_samples(geo_id):
    """获取特定数据集的样本信息"""
    try:
        dataset = Dataset.query.filter_by(geo_id=geo_id).first()
        if not dataset:
            return jsonify({'error': 'Dataset not found'}), 404
        
        page = request.args.get('page', 1, type=int)
        per_page = request.args.get('per_page', 50, type=int)
        tumor_type = request.args.get('tumor_type')
        grade = request.args.get('grade')
        
        query = Sample.query.filter(Sample.dataset_id == dataset.id)
        
        if tumor_type:
            query = query.filter(Sample.tumor_type == tumor_type)
        if grade:
            query = query.filter(Sample.grade == grade)
        
        samples = query.paginate(
            page=page, per_page=per_page, error_out=False
        )
        
        return jsonify({
            'samples': [{
                'id': s.id,
                'sample_id': s.sample_id,
                'sample_name': s.sample_name,
                'tissue_type': s.tissue_type,
                'tumor_type': s.tumor_type,
                'tumor_subtype': s.tumor_subtype,
                'grade': s.grade,
                'stage': s.stage,
                'age': s.age,
                'gender': s.gender,
                'survival_status': s.survival_status,
                'survival_time': s.survival_time,
                'treatment_type': s.treatment_type,
                'metastasis_status': s.metastasis_status,
                'quality_score': float(s.quality_score) if s.quality_score else None
            } for s in samples.items],
            'total': samples.total,
            'pages': samples.pages,
            'current_page': page
        })
    except Exception as e:
        logger.error(f"Error getting samples: {str(e)}")
        return jsonify({'error': str(e)}), 500

# 2. 基因表达相关API
@app.route('/api/datasets/<geo_id>/expression', methods=['GET'])
def get_gene_expression(geo_id):
    """获取基因表达数据"""
    try:
        dataset = Dataset.query.filter_by(geo_id=geo_id).first()
        if not dataset:
            return jsonify({'error': 'Dataset not found'}), 404
        
        gene_symbol = request.args.get('gene_symbol')
        sample_ids = request.args.getlist('sample_ids')
        min_expression = request.args.get('min_expression', type=float)
        max_expression = request.args.get('max_expression', type=float)
        
        query = GeneExpression.query.filter(GeneExpression.dataset_id == dataset.id)
        
        if gene_symbol:
            query = query.filter(GeneExpression.gene_symbol == gene_symbol)
        if sample_ids:
            query = query.filter(GeneExpression.sample_id.in_(sample_ids))
        if min_expression is not None:
            query = query.filter(GeneExpression.expression_value >= min_expression)
        if max_expression is not None:
            query = query.filter(GeneExpression.expression_value <= max_expression)
        
        # 限制返回数量，避免内存问题
        expressions = query.limit(10000).all()
        
        return jsonify({
            'expressions': [{
                'sample_id': e.sample_id,
                'gene_symbol': e.gene_symbol,
                'expression_value': float(e.expression_value) if e.expression_value else None,
                'log2_expression': float(e.log2_expression) if e.log2_expression else None,
                'normalized_value': float(e.normalized_value) if e.normalized_value else None,
                'is_expressed': e.is_expressed
            } for e in expressions]
        })
    except Exception as e:
        logger.error(f"Error getting gene expression: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/datasets/<geo_id>/genes', methods=['GET'])
def get_dataset_genes(geo_id):
    """获取数据集的基因列表"""
    try:
        dataset = Dataset.query.filter_by(geo_id=geo_id).first()
        if not dataset:
            return jsonify({'error': 'Dataset not found'}), 404
        
        page = request.args.get('page', 1, type=int)
        per_page = request.args.get('per_page', 100, type=int)
        gene_type = request.args.get('gene_type')
        chromosome = request.args.get('chromosome')
        search_term = request.args.get('search')
        
        query = db.session.query(Gene).join(GeneExpression).filter(
            GeneExpression.dataset_id == dataset.id
        ).distinct()
        
        if gene_type:
            query = query.filter(Gene.gene_type == gene_type)
        if chromosome:
            query = query.filter(Gene.chromosome == chromosome)
        if search_term:
            query = query.filter(
                or_(
                    Gene.gene_symbol.contains(search_term),
                    Gene.gene_name.contains(search_term)
                )
            )
        
        genes = query.paginate(
            page=page, per_page=per_page, error_out=False
        )
        
        return jsonify({
            'genes': [{
                'gene_id': g.gene_id,
                'gene_symbol': g.gene_symbol,
                'gene_name': g.gene_name,
                'chromosome': g.chromosome,
                'gene_type': g.gene_type,
                'description': g.description
            } for g in genes.items],
            'total': genes.total,
            'pages': genes.pages,
            'current_page': page
        })
    except Exception as e:
        logger.error(f"Error getting genes: {str(e)}")
        return jsonify({'error': str(e)}), 500

# 3. 分析相关API
@app.route('/api/analysis/differential_expression', methods=['POST'])
def run_differential_expression():
    """运行差异表达分析"""
    try:
        data = request.json
        dataset_id = data.get('dataset_id')
        group1 = data.get('group1')
        group2 = data.get('group2')
        fc_threshold = data.get('fc_threshold', 1.5)
        pval_threshold = data.get('pval_threshold', 0.05)
        
        if not all([dataset_id, group1, group2]):
            return jsonify({'error': 'Missing required parameters'}), 400
        
        # 创建分析任务
        task = AnalysisTask(
            dataset_id=dataset_id,
            task_type='differential_expression',
            task_name=f'DE Analysis: {group1} vs {group2}',
            parameters=data,
            status='pending'
        )
        db.session.add(task)
        db.session.commit()
        
        # 这里应该调用R脚本进行实际分析
        # 为了演示，我们返回模拟结果
        return jsonify({
            'task_id': task.id,
            'status': 'pending',
            'message': 'Analysis task created successfully'
        })
    except Exception as e:
        logger.error(f"Error running differential expression: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/analysis/survival', methods=['POST'])
def run_survival_analysis():
    """运行生存分析"""
    try:
        data = request.json
        dataset_id = data.get('dataset_id')
        gene_symbol = data.get('gene_symbol')
        analysis_type = data.get('analysis_type', 'overall_survival')
        cutoff_method = data.get('cutoff_method', 'median')
        
        if not all([dataset_id, gene_symbol]):
            return jsonify({'error': 'Missing required parameters'}), 400
        
        # 创建分析任务
        task = AnalysisTask(
            dataset_id=dataset_id,
            task_type='survival_analysis',
            task_name=f'Survival Analysis: {gene_symbol}',
            parameters=data,
            status='pending'
        )
        db.session.add(task)
        db.session.commit()
        
        return jsonify({
            'task_id': task.id,
            'status': 'pending',
            'message': 'Survival analysis task created successfully'
        })
    except Exception as e:
        logger.error(f"Error running survival analysis: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/analysis/tasks/<int:task_id>', methods=['GET'])
def get_analysis_task(task_id):
    """获取分析任务状态"""
    try:
        task = AnalysisTask.query.get(task_id)
        if not task:
            return jsonify({'error': 'Task not found'}), 404
        
        return jsonify({
            'id': task.id,
            'task_type': task.task_type,
            'task_name': task.task_name,
            'status': task.status,
            'progress': task.progress,
            'result_summary': task.result_summary,
            'error_message': task.error_message,
            'created_at': task.created_at.isoformat(),
            'started_at': task.started_at.isoformat() if task.started_at else None,
            'completed_at': task.completed_at.isoformat() if task.completed_at else None
        })
    except Exception as e:
        logger.error(f"Error getting task: {str(e)}")
        return jsonify({'error': str(e)}), 500

# 4. 统计信息API
@app.route('/api/statistics/overview', methods=['GET'])
def get_statistics_overview():
    """获取数据库统计概览"""
    try:
        stats = {
            'total_datasets': Dataset.query.count(),
            'total_samples': Sample.query.count(),
            'total_genes': Gene.query.count(),
            'total_expressions': GeneExpression.query.count(),
            'tissue_types': db.session.query(
                Dataset.tissue_type, func.count(Dataset.id)
            ).group_by(Dataset.tissue_type).all(),
            'tumor_types': db.session.query(
                Dataset.tumor_type, func.count(Dataset.id)
            ).group_by(Dataset.tumor_type).all(),
            'publication_years': db.session.query(
                Dataset.publication_year, func.count(Dataset.id)
            ).group_by(Dataset.publication_year).order_by(Dataset.publication_year).all()
        }
        
        return jsonify(stats)
    except Exception as e:
        logger.error(f"Error getting statistics: {str(e)}")
        return jsonify({'error': str(e)}), 500

# 5. 数据导入API
@app.route('/api/import/dataset', methods=['POST'])
def import_dataset():
    """导入新的数据集"""
    try:
        data = request.json
        geo_id = data.get('geo_id')
        
        if not geo_id:
            return jsonify({'error': 'GEO ID is required'}), 400
        
        # 检查数据集是否已存在
        existing_dataset = Dataset.query.filter_by(geo_id=geo_id).first()
        if existing_dataset:
            return jsonify({'error': 'Dataset already exists'}), 400
        
        # 创建新数据集记录
        dataset = Dataset(
            geo_id=geo_id,
            title=data.get('title', f'Dataset {geo_id}'),
            description=data.get('description'),
            tissue_type=data.get('tissue_type'),
            tumor_type=data.get('tumor_type'),
            platform=data.get('platform'),
            n_samples=data.get('n_samples'),
            n_genes=data.get('n_genes'),
            publication_year=data.get('publication_year'),
            reference_pmid=data.get('reference_pmid'),
            file_path=data.get('file_path')
        )
        
        db.session.add(dataset)
        db.session.commit()
        
        return jsonify({
            'id': dataset.id,
            'geo_id': dataset.geo_id,
            'message': 'Dataset imported successfully'
        })
    except Exception as e:
        logger.error(f"Error importing dataset: {str(e)}")
        return jsonify({'error': str(e)}), 500

# 错误处理
@app.errorhandler(404)
def not_found(error):
    return jsonify({'error': 'Resource not found'}), 404

@app.errorhandler(500)
def internal_error(error):
    db.session.rollback()
    return jsonify({'error': 'Internal server error'}), 500

# 健康检查
@app.route('/api/health', methods=['GET'])
def health_check():
    """健康检查端点"""
    try:
        # 检查数据库连接
        db.session.execute(text('SELECT 1'))
        return jsonify({
            'status': 'healthy',
            'database': 'connected',
            'timestamp': datetime.utcnow().isoformat()
        })
    except Exception as e:
        return jsonify({
            'status': 'unhealthy',
            'database': 'disconnected',
            'error': str(e),
            'timestamp': datetime.utcnow().isoformat()
        }), 500

if __name__ == '__main__':
    # 创建数据库表
    with app.app_context():
        db.create_all()
    
    # 启动应用
    app.run(host='0.0.0.0', port=5000, debug=True)
