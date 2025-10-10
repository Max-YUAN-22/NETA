import React, { useState } from 'react';
import { Form, Button, Card, Alert, Spinner } from 'react-bootstrap';
import { ScatterChart, Scatter, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { api } from '../services/api';

function PCAPage() {
  const [formData, setFormData] = useState({
    dataset_id: '',
    n_components: 2,
    color_by: 'tumor_type'
  });
  const [results, setResults] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      const response = await api.runPCAAnalysis(formData);
      if (response.ok) {
        const data = await response.json();
        setResults(data.results);
      } else {
        setError('PCA分析失败');
      }
    } catch (err) {
      setError('网络错误: ' + err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: name === 'dataset_id' || name === 'n_components' ? parseInt(value) : value
    }));
  };

  return (
    <div>
      <h2>📊 PCA分析</h2>
      <p className="text-muted">主成分分析降维可视化</p>

      <Card className="mb-4">
        <Card.Header>
          <h5>分析参数</h5>
        </Card.Header>
        <Card.Body>
          <Form onSubmit={handleSubmit}>
            <Form.Group className="mb-3">
              <Form.Label>数据集ID</Form.Label>
              <Form.Control
                type="number"
                name="dataset_id"
                value={formData.dataset_id}
                onChange={handleInputChange}
                placeholder="输入数据集ID"
                required
              />
            </Form.Group>
            <Form.Group className="mb-3">
              <Form.Label>主成分数量</Form.Label>
              <Form.Select
                name="n_components"
                value={formData.n_components}
                onChange={handleInputChange}
              >
                <option value={2}>2个主成分</option>
                <option value={3}>3个主成分</option>
              </Form.Select>
            </Form.Group>
            <Form.Group className="mb-3">
              <Form.Label>颜色分组</Form.Label>
              <Form.Select
                name="color_by"
                value={formData.color_by}
                onChange={handleInputChange}
              >
                <option value="tumor_type">肿瘤类型</option>
                <option value="tissue_type">组织类型</option>
                <option value="grade">分级</option>
              </Form.Select>
            </Form.Group>
            <Button variant="primary" type="submit" disabled={loading}>
              {loading ? (
                <>
                  <Spinner size="sm" className="me-2" />
                  分析中...
                </>
              ) : (
                '开始PCA分析'
              )}
            </Button>
          </Form>
        </Card.Body>
      </Card>

      {error && <Alert variant="danger">{error}</Alert>}

      {results && (
        <Card>
          <Card.Header>
            <h5>PCA分析结果</h5>
          </Card.Header>
          <Card.Body>
            <div style={{ height: '400px' }}>
              <ResponsiveContainer width="100%" height="100%">
                <ScatterChart data={results.pca_data}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis 
                    dataKey="PC1" 
                    name="PC1"
                    label={{ value: 'PC1', position: 'insideBottom', offset: -10 }}
                  />
                  <YAxis 
                    dataKey="PC2" 
                    name="PC2"
                    label={{ value: 'PC2', angle: -90, position: 'insideLeft' }}
                  />
                  <Tooltip />
                  <Scatter 
                    dataKey="PC2" 
                    fill="#8884d8" 
                    name="样本"
                  />
                </ScatterChart>
              </ResponsiveContainer>
            </div>
            <div className="mt-3">
              <h6>解释方差比例:</h6>
              <ul>
                <li>PC1: {(results.explained_variance_ratio[0] * 100).toFixed(1)}%</li>
                <li>PC2: {(results.explained_variance_ratio[1] * 100).toFixed(1)}%</li>
              </ul>
            </div>
          </Card.Body>
        </Card>
      )}
    </div>
  );
}

export default PCAPage;
