import React, { useState } from 'react';
import { Form, Button, Card, Alert, Spinner } from 'react-bootstrap';
import { ScatterChart, Scatter, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { api } from '../services/api';

function VolcanoPage() {
  const [formData, setFormData] = useState({
    dataset_id: '',
    group1: '',
    group2: '',
    pvalue_cutoff: 0.05,
    logfc_cutoff: 1.0
  });
  const [results, setResults] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      const response = await api.runDifferentialExpression(formData);
      if (response.ok) {
        const data = await response.json();
        setResults(data.results);
      } else {
        setError('差异表达分析失败');
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
      [name]: name === 'dataset_id' || name === 'pvalue_cutoff' || name === 'logfc_cutoff' 
        ? parseFloat(value) : value
    }));
  };

  return (
    <div>
      <h2>🌋 火山图</h2>
      <p className="text-muted">差异表达基因可视化分析</p>

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
              <Form.Label>比较组1</Form.Label>
              <Form.Control
                type="text"
                name="group1"
                value={formData.group1}
                onChange={handleInputChange}
                placeholder="如: Normal, Control"
                required
              />
            </Form.Group>
            <Form.Group className="mb-3">
              <Form.Label>比较组2</Form.Label>
              <Form.Control
                type="text"
                name="group2"
                value={formData.group2}
                onChange={handleInputChange}
                placeholder="如: Tumor, Case"
                required
              />
            </Form.Group>
            <Form.Group className="mb-3">
              <Form.Label>P值阈值</Form.Label>
              <Form.Control
                type="number"
                name="pvalue_cutoff"
                value={formData.pvalue_cutoff}
                onChange={handleInputChange}
                step="0.01"
                min="0"
                max="1"
              />
            </Form.Group>
            <Form.Group className="mb-3">
              <Form.Label>Log2FC阈值</Form.Label>
              <Form.Control
                type="number"
                name="logfc_cutoff"
                value={formData.logfc_cutoff}
                onChange={handleInputChange}
                step="0.1"
                min="0"
              />
            </Form.Group>
            <Button variant="primary" type="submit" disabled={loading}>
              {loading ? (
                <>
                  <Spinner size="sm" className="me-2" />
                  分析中...
                </>
              ) : (
                '开始差异表达分析'
              )}
            </Button>
          </Form>
        </Card.Body>
      </Card>

      {error && <Alert variant="danger">{error}</Alert>}

      {results && (
        <Card>
          <Card.Header>
            <h5>火山图结果</h5>
          </Card.Header>
          <Card.Body>
            <div style={{ height: '500px' }}>
              <ResponsiveContainer width="100%" height="100%">
                <ScatterChart data={results.volcano_data}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis 
                    dataKey="log2FoldChange" 
                    name="Log2 Fold Change"
                    label={{ value: 'Log2 Fold Change', position: 'insideBottom', offset: -10 }}
                  />
                  <YAxis 
                    dataKey="negLog10Pvalue" 
                    name="-Log10 P-value"
                    label={{ value: '-Log10 P-value', angle: -90, position: 'insideLeft' }}
                  />
                  <Tooltip 
                    formatter={(value, name) => [value, name]}
                    labelFormatter={(label) => `Log2FC: ${label}`}
                  />
                  <Scatter 
                    dataKey="negLog10Pvalue" 
                    fill="#8884d8" 
                    name="基因"
                  />
                </ScatterChart>
              </ResponsiveContainer>
            </div>
            <div className="mt-3">
              <h6>统计结果:</h6>
              <ul>
                <li>上调基因: {results.upregulated_count} 个</li>
                <li>下调基因: {results.downregulated_count} 个</li>
                <li>显著差异基因: {results.significant_count} 个</li>
              </ul>
            </div>
          </Card.Body>
        </Card>
      )}
    </div>
  );
}

export default VolcanoPage;
