import React, { useState, useEffect } from 'react';
import { Table, Card, Spinner, Alert, Pagination } from 'react-bootstrap';
import { api } from '../services/api';

function DatasetsPage() {
  const [datasets, setDatasets] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [currentPage, setCurrentPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);

  useEffect(() => {
    fetchDatasets();
  }, [currentPage]);

  const fetchDatasets = async () => {
    try {
      setLoading(true);
      const response = await api.getDatasets(currentPage, 20);
      if (response.ok) {
        const data = await response.json();
        setDatasets(data.datasets);
        setTotalPages(data.pages);
      } else {
        setError('Failed to fetch datasets');
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
      <h2>📊 数据集列表</h2>
      <p className="text-muted">优先展示 RNA-seq（原始计数）数据集；微阵列在列表靠后</p>

      <Card>
        <Card.Body>
          <Table responsive striped hover>
            <thead>
              <tr>
                <th>GEO ID</th>
                <th>标题</th>
                <th>组织类型</th>
                <th>肿瘤类型</th>
                <th>测序类型</th>
                <th>样本数</th>
                <th>基因数</th>
                <th>发表年份</th>
              </tr>
            </thead>
            <tbody>
              {datasets
                .slice()
                .sort((a,b)=>{
                  const ra = (a.assay_type||'')==='RNA-seq'?0:1;
                  const rb = (b.assay_type||'')==='RNA-seq'?0:1;
                  return ra - rb;
                })
                .map((dataset) => (
                <tr key={dataset.id}>
                  <td>
                    <code>{dataset.geo_id}</code>
                  </td>
                  <td>{dataset.title}</td>
                  <td>
                    <span className="badge bg-primary">
                      {dataset.tissue_type}
                    </span>
                  </td>
                  <td>
                    <span className="badge bg-secondary">
                      {dataset.tumor_type}
                    </span>
                  </td>
                  <td>
                    {dataset.assay_type === 'RNA-seq' ? (
                      <span className="badge bg-success">RNA-seq</span>
                    ) : (
                      <span className="badge bg-light text-dark">Microarray</span>
                    )}
                  </td>
                  <td>{dataset.n_samples}</td>
                  <td>{dataset.n_genes?.toLocaleString()}</td>
                  <td>{dataset.publication_year}</td>
                </tr>
              ))}
            </tbody>
          </Table>

          {totalPages > 1 && (
            <div className="d-flex justify-content-center">
              <Pagination>
                <Pagination.Prev 
                  disabled={currentPage === 1}
                  onClick={() => setCurrentPage(currentPage - 1)}
                />
                {[...Array(totalPages)].map((_, i) => (
                  <Pagination.Item
                    key={i + 1}
                    active={i + 1 === currentPage}
                    onClick={() => setCurrentPage(i + 1)}
                  >
                    {i + 1}
                  </Pagination.Item>
                ))}
                <Pagination.Next 
                  disabled={currentPage === totalPages}
                  onClick={() => setCurrentPage(currentPage + 1)}
                />
              </Pagination>
            </div>
          )}
        </Card.Body>
      </Card>
    </div>
  );
}

export default DatasetsPage;
