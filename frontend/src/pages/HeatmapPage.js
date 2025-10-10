import React, { useState } from 'react';
import { Form, Button, Card, Alert, Spinner } from 'react-bootstrap';
import { api } from '../services/api';

function HeatmapPage() {
  const [formData, setFormData] = useState({
    dataset_id: '',
    gene_list: '',
    n_genes: 50,
    clustering_method: 'hierarchical'
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
        setError('热图分析失败');
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
      [name]: name === 'dataset_id' || name === 'n_genes' 
        ? parseInt(value) : value
    }));
  };

  return (
    <div>
      <h2>🔥 热图</h2>
      <p className="text-muted">基因表达聚类热图分析</p>

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
              <Form.Label>基因列表 (可选)</Form.Label>
              <Form.Control
                as="textarea"
                rows={3}
                name="gene_list"
                value={formData.gene_list}
                onChange={handleInputChange}
                placeholder="输入基因符号，用逗号分隔，如: TP53, BRCA1, MYC"
              />
              <Form.Text className="text-muted">
                留空则使用差异表达分析结果中的前N个基因
              </Form.Text>
            </Form.Group>
            <Form.Group className="mb-3">
              <Form.Label>基因数量</Form.Label>
              <Form.Control
                type="number"
                name="n_genes"
                value={formData.n_genes}
                onChange={handleInputChange}
                min="10"
                max="500"
              />
            </Form.Group>
            <Form.Group className="mb-3">
              <Form.Label>聚类方法</Form.Label>
              <Form.Select
                name="clustering_method"
                value={formData.clustering_method}
                onChange={handleInputChange}
              >
                <option value="hierarchical">层次聚类</option>
                <option value="kmeans">K-means聚类</option>
                <option value="none">不聚类</option>
              </Form.Select>
            </Form.Group>
            <Button variant="primary" type="submit" disabled={loading}>
              {loading ? (
                <>
                  <Spinner size="sm" className="me-2" />
                  分析中...
                </>
              ) : (
                '生成热图'
              )}
            </Button>
          </Form>
        </Card.Body>
      </Card>

      {error && <Alert variant="danger">{error}</Alert>}

      {results && (
        <Card>
          <Card.Header>
            <h5>热图结果</h5>
          </Card.Header>
          <Card.Body>
            {results.heatmap_image ? (
              <div className="text-center">
                <img 
                  src={`data:image/png;base64,${results.heatmap_image}`}
                  alt="热图"
                  className="img-fluid"
                  style={{ maxHeight: '600px' }}
                />
              </div>
            ) : (
              <div className="text-center text-muted">
                <p>热图生成中...</p>
                <Spinner animation="border" />
              </div>
            )}
            <div className="mt-3">
              <h6>分析信息:</h6>
              <ul>
                <li>包含基因数: {results.n_genes} 个</li>
                <li>包含样本数: {results.n_samples} 个</li>
                <li>聚类方法: {formData.clustering_method}</li>
              </ul>
            </div>
          </Card.Body>
        </Card>
      )}
    </div>
  );
}

export default HeatmapPage;
