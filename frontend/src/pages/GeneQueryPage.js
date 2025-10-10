import React, { useState } from 'react';
import { Form, Button, Card, Table, Alert, Spinner } from 'react-bootstrap';
import { api } from '../services/api';

function GeneQueryPage() {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const handleSearch = async (e) => {
    e.preventDefault();
    if (!query.trim()) return;

    setLoading(true);
    setError(null);

    try {
      const response = await api.searchGenes(query);
      if (response.ok) {
        const data = await response.json();
        setResults(data);
      } else {
        setError('搜索失败');
      }
    } catch (err) {
      setError('网络错误: ' + err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div>
      <h2>🔍 基因查询</h2>
      <p className="text-muted">搜索基因符号或基因名称</p>

      <Card className="mb-4">
        <Card.Body>
          <Form onSubmit={handleSearch}>
            <Form.Group className="mb-3">
              <Form.Label>基因查询</Form.Label>
              <Form.Control
                type="text"
                placeholder="输入基因符号或名称，如: TP53, BRCA1"
                value={query}
                onChange={(e) => setQuery(e.target.value)}
              />
            </Form.Group>
            <Button variant="primary" type="submit" disabled={loading}>
              {loading ? (
                <>
                  <Spinner size="sm" className="me-2" />
                  搜索中...
                </>
              ) : (
                '搜索'
              )}
            </Button>
          </Form>
        </Card.Body>
      </Card>

      {error && <Alert variant="danger">{error}</Alert>}

      {results.length > 0 && (
        <Card>
          <Card.Header>
            <h5>搜索结果 ({results.length} 个基因)</h5>
          </Card.Header>
          <Card.Body>
            <Table responsive striped hover>
              <thead>
                <tr>
                  <th>基因ID</th>
                  <th>基因符号</th>
                  <th>基因名称</th>
                  <th>染色体</th>
                  <th>基因类型</th>
                </tr>
              </thead>
              <tbody>
                {results.map((gene) => (
                  <tr key={gene.id}>
                    <td>
                      <code>{gene.gene_id}</code>
                    </td>
                    <td>
                      <strong>{gene.gene_symbol}</strong>
                    </td>
                    <td>{gene.gene_name}</td>
                    <td>{gene.chromosome}</td>
                    <td>
                      <span className="badge bg-info">
                        {gene.gene_type}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </Table>
          </Card.Body>
        </Card>
      )}
    </div>
  );
}

export default GeneQueryPage;
