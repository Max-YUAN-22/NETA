import React, { useState, useEffect } from 'react';
import { Card, Row, Col, Spinner, Alert } from 'react-bootstrap';
import { api } from '../services/api';

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
    return (
      <div className="text-center">
        <Spinner animation="border" role="status">
          <span className="visually-hidden">Loading...</span>
        </Spinner>
      </div>
    );
  }

  if (error) {
    return <Alert variant="danger">{error}</Alert>;
  }

  return (
    <div>
      <div className="text-center mb-5">
        <h1 className="display-4">🧬 NETA</h1>
        <p className="lead">泛神经内分泌癌转录组学分析平台</p>
        <p className="text-muted">
          基于28个真实GEO数据集，提供全面的生物信息学分析功能
        </p>
      </div>

      {statistics && (
        <Row className="mb-5">
          <Col md={3}>
            <Card className="text-center h-100">
              <Card.Body>
                <Card.Title className="display-6 text-primary">
                  {statistics.total_datasets}
                </Card.Title>
                <Card.Text>数据集</Card.Text>
              </Card.Body>
            </Card>
          </Col>
          <Col md={3}>
            <Card className="text-center h-100">
              <Card.Body>
                <Card.Title className="display-6 text-success">
                  {statistics.total_samples?.toLocaleString()}
                </Card.Title>
                <Card.Text>样本</Card.Text>
              </Card.Body>
            </Card>
          </Col>
          <Col md={3}>
            <Card className="text-center h-100">
              <Card.Body>
                <Card.Title className="display-6 text-warning">
                  {statistics.total_genes?.toLocaleString()}
                </Card.Title>
                <Card.Text>基因</Card.Text>
              </Card.Body>
            </Card>
          </Col>
          <Col md={3}>
            <Card className="text-center h-100">
              <Card.Body>
                <Card.Title className="display-6 text-info">
                  {(statistics.total_expressions / 1000000).toFixed(1)}M
                </Card.Title>
                <Card.Text>表达记录</Card.Text>
              </Card.Body>
            </Card>
          </Col>
        </Row>
      )}

      <Row>
        <Col md={6}>
          <Card className="h-100">
            <Card.Header>
              <h5>🔬 分析功能</h5>
            </Card.Header>
            <Card.Body>
              <ul className="list-unstyled">
                <li>✅ 差异表达分析 (DESeq2)</li>
                <li>✅ 主成分分析 (PCA)</li>
                <li>✅ 富集分析 (KEGG/GO)</li>
                <li>✅ 生存分析 (Kaplan-Meier)</li>
                <li>✅ 基因查询与可视化</li>
              </ul>
            </Card.Body>
          </Card>
        </Col>
        <Col md={6}>
          <Card className="h-100">
            <Card.Header>
              <h5>📊 数据来源</h5>
            </Card.Header>
            <Card.Body>
              <ul className="list-unstyled">
                <li>🧬 胰腺神经内分泌肿瘤</li>
                <li>🧬 前列腺神经内分泌癌</li>
                <li>🧬 胃肠道神经内分泌肿瘤</li>
                <li>🧬 小细胞肺癌</li>
                <li>🧬 其他相关癌症类型</li>
              </ul>
            </Card.Body>
          </Card>
        </Col>
      </Row>
    </div>
  );
}

export default HomePage;
