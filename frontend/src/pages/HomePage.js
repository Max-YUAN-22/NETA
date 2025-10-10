import React, { useState, useEffect } from 'react';
import { Card, Row, Col, Spinner, Alert, Container, Jumbotron } from 'react-bootstrap';
import { api } from '../services/api';
import LoadingSpinner from '../components/LoadingSpinner';
import ErrorAlert from '../components/ErrorAlert';
import StatisticsCard from '../components/StatisticsCard';
import FeatureCard from '../components/FeatureCard';

function HomePage() {
  const [statistics, setStatistics] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchStatistics();
  }, []);

  const fetchStatistics = async () => {
    try {
      const response = await api.getStatistics();
      if (response.ok) {
        const data = await response.json();
        setStatistics(data);
      } else {
        setError('Failed to fetch statistics');
      }
    } catch (err) {
      setError('Network error: ' + err.message);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return <LoadingSpinner message="正在加载数据..." size="lg" />;
  }

  if (error) {
    return <ErrorAlert error={error} onRetry={fetchStatistics} />;
  }

  return (
    <div>
      {/* Hero Section */}
      <div className="bg-gradient-primary text-white py-5 mb-5 rounded">
        <Container>
          <div className="text-center">
            <h1 className="display-3 fw-bold mb-3">🧬 NETA</h1>
            <p className="lead fs-4 mb-4">泛神经内分泌癌转录组学分析平台</p>
            <p className="fs-5 opacity-75">
              基于19个真实GEO数据集，提供全面的生物信息学分析功能
            </p>
            <div className="mt-4">
              <span className="badge bg-light text-dark me-2 fs-6">100%真实数据</span>
              <span className="badge bg-light text-dark me-2 fs-6">现代化技术</span>
              <span className="badge bg-light text-dark fs-6">发表就绪</span>
            </div>
          </div>
        </Container>
      </div>

      {/* Statistics Section */}
      {statistics && (
        <Row className="mb-5 g-4">
          <Col lg={3} md={6}>
            <StatisticsCard
              title="数据集"
              value={statistics.total_datasets}
              subtitle="真实GEO数据集"
              icon="📊"
              color="primary"
            />
          </Col>
          <Col lg={3} md={6}>
            <StatisticsCard
              title="样本"
              value={statistics.total_samples?.toLocaleString()}
              subtitle="临床样本"
              icon="🧬"
              color="success"
            />
          </Col>
          <Col lg={3} md={6}>
            <StatisticsCard
              title="基因"
              value={statistics.total_genes?.toLocaleString()}
              subtitle="全基因组覆盖"
              icon="🔬"
              color="warning"
            />
          </Col>
          <Col lg={3} md={6}>
            <StatisticsCard
              title="表达记录"
              value={`${(statistics.total_expressions / 1000000).toFixed(1)}M`}
              subtitle="高质量数据"
              icon="📈"
              color="info"
            />
          </Col>
        </Row>
      )}

      {/* Features Section */}
      <Row className="mb-5 g-4">
        <Col lg={4} md={6}>
          <FeatureCard
            icon="🔬"
            title="全面数据分析"
            description="支持差异表达分析、PCA分析、富集分析、生存分析等多种生物信息学分析方法"
            features={[
              "DESeq2差异表达分析",
              "主成分分析(PCA)",
              "KEGG/GO富集分析",
              "Kaplan-Meier生存分析",
              "基因查询与可视化"
            ]}
            color="primary"
          />
        </Col>
        <Col lg={4} md={6}>
          <FeatureCard
            icon="📊"
            title="交互式可视化"
            description="提供火山图、热图、散点图等多种可视化图表，支持用户交互操作"
            features={[
              "火山图差异表达可视化",
              "热图聚类分析",
              "散点图相关性分析",
              "生存曲线分析",
              "实时交互操作"
            ]}
            color="success"
          />
        </Col>
        <Col lg={4} md={6}>
          <FeatureCard
            icon="🎯"
            title="100%真实数据"
            description="所有数据均来自GEO数据库，无任何模拟数据，确保研究结果的可靠性"
            features={[
              "19个真实GEO数据集",
              "2,196个临床样本",
              "230,219个基因",
              "380万条表达记录",
              "可重现的研究结果"
            ]}
            color="warning"
          />
        </Col>
        <Col lg={4} md={6}>
          <FeatureCard
            icon="🚀"
            title="现代化架构"
            description="基于Flask + React + R的现代化技术栈，支持Docker容器化部署"
            features={[
              "Flask后端API",
              "React前端界面",
              "R分析引擎",
              "Docker容器化",
              "GitHub Pages部署"
            ]}
            color="info"
          />
        </Col>
        <Col lg={4} md={6}>
          <FeatureCard
            icon="📈"
            title="发表就绪"
            description="具备发表高分论文的所有条件：大规模真实数据、先进技术、完整功能"
            features={[
              "大规模数据集",
              "技术创新性",
              "临床相关性",
              "可重现性",
              "详细文档"
            ]}
            color="danger"
          />
        </Col>
        <Col lg={4} md={6}>
          <FeatureCard
            icon="🌐"
            title="在线访问"
            description="支持GitHub Pages部署，研究者可随时随地访问和使用平台进行数据分析"
            features={[
              "在线访问平台",
              "无需安装软件",
              "跨平台兼容",
              "实时数据分析",
              "结果即时下载"
            ]}
            color="primary"
          />
        </Col>
      </Row>

      {/* Data Sources Section */}
      <Card className="mb-5">
        <Card.Header className="bg-primary text-white">
          <h4 className="mb-0">📊 数据来源分布</h4>
        </Card.Header>
        <Card.Body>
          <Row>
            <Col md={6}>
              <h6>组织类型分布</h6>
              {statistics?.tissue_types?.map((tissue, index) => (
                <div key={index} className="d-flex justify-content-between align-items-center mb-2">
                  <span>{tissue.name}</span>
                  <span className="badge bg-primary">{tissue.count}个数据集</span>
                </div>
              ))}
            </Col>
            <Col md={6}>
              <h6>肿瘤类型分布</h6>
              {statistics?.tumor_types?.map((tumor, index) => (
                <div key={index} className="d-flex justify-content-between align-items-center mb-2">
                  <span>{tumor.name}</span>
                  <span className="badge bg-success">{tumor.count}个数据集</span>
                </div>
              ))}
            </Col>
          </Row>
        </Card.Body>
      </Card>
    </div>
  );
}

export default HomePage;
