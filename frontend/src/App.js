// NETA前端React应用
// 神经内分泌肿瘤数据库前端界面

import React, { useState, useEffect } from 'react';
import axios from 'axios';
import {
  BrowserRouter as Router,
  Routes,
  Route,
  Link,
  useParams
} from 'react-router-dom';
import {
  Container,
  Row,
  Col,
  Card,
  Table,
  Button,
  Form,
  InputGroup,
  Dropdown,
  Pagination,
  Spinner,
  Alert,
  Modal,
  Tabs,
  Tab
} from 'react-bootstrap';
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  BarChart,
  Bar,
  PieChart,
  Pie,
  Cell,
  ScatterChart,
  Scatter
} from 'recharts';
import './App.css';

// API基础URL
const API_BASE_URL = 'http://localhost:5000/api';

// 主应用组件
function App() {
  return (
    <Router>
      <div className="App">
        <header className="app-header">
          <Container>
            <Row className="align-items-center">
              <Col md={6}>
                <h1 className="app-title">
                  🧬 NETA: Neuroendocrine Tumor Atlas
                </h1>
                <p className="app-subtitle">
                  神经内分泌肿瘤转录组图谱数据库
                </p>
              </Col>
              <Col md={6} className="text-end">
                <nav className="app-nav">
                  <Link to="/" className="nav-link">首页</Link>
                  <Link to="/datasets" className="nav-link">数据集</Link>
                  <Link to="/analysis" className="nav-link">分析</Link>
                  <Link to="/statistics" className="nav-link">统计</Link>
                </nav>
              </Col>
            </Row>
          </Container>
        </header>

        <main className="app-main">
          <Container fluid>
            <Routes>
              <Route path="/" element={<HomePage />} />
              <Route path="/datasets" element={<DatasetsPage />} />
              <Route path="/datasets/:geoId" element={<DatasetDetailPage />} />
              <Route path="/analysis" element={<AnalysisPage />} />
              <Route path="/statistics" element={<StatisticsPage />} />
            </Routes>
          </Container>
        </main>

        <footer className="app-footer">
          <Container>
            <Row>
              <Col md={12} className="text-center">
                <p>&copy; 2024 NETA Project. All rights reserved.</p>
              </Col>
            </Row>
          </Container>
        </footer>
      </div>
    </Router>
  );
}

// 首页组件
function HomePage() {
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchStatistics();
  }, []);

  const fetchStatistics = async () => {
    try {
      const response = await axios.get(`${API_BASE_URL}/statistics/overview`);
      setStats(response.data);
    } catch (error) {
      console.error('Error fetching statistics:', error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <Container className="text-center py-5">
        <Spinner animation="border" role="status">
          <span className="visually-hidden">Loading...</span>
        </Spinner>
      </Container>
    );
  }

  return (
    <Container className="py-5">
      <Row>
        <Col md={12}>
          <h2 className="mb-4">欢迎使用NETA数据库</h2>
          <p className="lead mb-5">
            NETA (Neuroendocrine Tumor Atlas) 是一个专门针对神经内分泌肿瘤的
            Bulk-RNA-seq数据库，提供全面的转录组分析和可视化功能。
          </p>
        </Col>
      </Row>

      <Row className="mb-5">
        <Col md={3}>
          <Card className="stat-card">
            <Card.Body className="text-center">
              <h3 className="stat-number">{stats?.total_datasets || 0}</h3>
              <p className="stat-label">数据集</p>
            </Card.Body>
          </Card>
        </Col>
        <Col md={3}>
          <Card className="stat-card">
            <Card.Body className="text-center">
              <h3 className="stat-number">{stats?.total_samples || 0}</h3>
              <p className="stat-label">样本</p>
            </Card.Body>
          </Card>
        </Col>
        <Col md={3}>
          <Card className="stat-card">
            <Card.Body className="text-center">
              <h3 className="stat-number">{stats?.total_genes || 0}</h3>
              <p className="stat-label">基因</p>
            </Card.Body>
          </Card>
        </Col>
        <Col md={3}>
          <Card className="stat-card">
            <Card.Body className="text-center">
              <h3 className="stat-number">{stats?.total_expressions || 0}</h3>
              <p className="stat-label">表达数据</p>
            </Card.Body>
          </Card>
        </Col>
      </Row>

      <Row>
        <Col md={6}>
          <Card>
            <Card.Header>
              <h5>组织类型分布</h5>
            </Card.Header>
            <Card.Body>
              <PieChart width={400} height={300}>
                <Pie
                  data={stats?.tissue_types || []}
                  dataKey="count"
                  nameKey="tissue_type"
                  cx="50%"
                  cy="50%"
                  outerRadius={80}
                  fill="#8884d8"
                  label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}
                >
                  {stats?.tissue_types?.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={`#${Math.floor(Math.random()*16777215).toString(16)}`} />
                  ))}
                </Pie>
                <Tooltip />
              </PieChart>
            </Card.Body>
          </Card>
        </Col>
        <Col md={6}>
          <Card>
            <Card.Header>
              <h5>发表年份分布</h5>
            </Card.Header>
            <Card.Body>
              <BarChart width={400} height={300} data={stats?.publication_years || []}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="publication_year" />
                <YAxis />
                <Tooltip />
                <Bar dataKey="count" fill="#82ca9d" />
              </BarChart>
            </Card.Body>
          </Card>
        </Col>
      </Row>
    </Container>
  );
}

// 数据集页面组件
function DatasetsPage() {
  const [datasets, setDatasets] = useState([]);
  const [loading, setLoading] = useState(true);
  const [currentPage, setCurrentPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [filters, setFilters] = useState({
    tissue_type: '',
    tumor_type: ''
  });

  useEffect(() => {
    fetchDatasets();
  }, [currentPage, filters]);

  const fetchDatasets = async () => {
    try {
      setLoading(true);
      const params = new URLSearchParams({
        page: currentPage,
        per_page: 10,
        ...filters
      });
      
      const response = await axios.get(`${API_BASE_URL}/datasets?${params}`);
      setDatasets(response.data.datasets);
      setTotalPages(response.data.pages);
    } catch (error) {
      console.error('Error fetching datasets:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleFilterChange = (key, value) => {
    setFilters(prev => ({ ...prev, [key]: value }));
    setCurrentPage(1);
  };

  if (loading) {
    return (
      <Container className="text-center py-5">
        <Spinner animation="border" role="status">
          <span className="visually-hidden">Loading...</span>
        </Spinner>
      </Container>
    );
  }

  return (
    <Container className="py-5">
      <Row className="mb-4">
        <Col md={12}>
          <h2>数据集列表</h2>
        </Col>
      </Row>

      <Row className="mb-4">
        <Col md={4}>
          <Form.Group>
            <Form.Label>组织类型</Form.Label>
            <Form.Select
              value={filters.tissue_type}
              onChange={(e) => handleFilterChange('tissue_type', e.target.value)}
            >
              <option value="">全部</option>
              <option value="Pancreas">胰腺</option>
              <option value="Lung">肺</option>
              <option value="Gastrointestinal">胃肠道</option>
            </Form.Select>
          </Form.Group>
        </Col>
        <Col md={4}>
          <Form.Group>
            <Form.Label>肿瘤类型</Form.Label>
            <Form.Select
              value={filters.tumor_type}
              onChange={(e) => handleFilterChange('tumor_type', e.target.value)}
            >
              <option value="">全部</option>
              <option value="Pancreatic NET">胰腺NET</option>
              <option value="SCLC">小细胞肺癌</option>
              <option value="GI-NET">胃肠道NET</option>
            </Form.Select>
          </Form.Group>
        </Col>
        <Col md={4} className="d-flex align-items-end">
          <Button variant="primary" onClick={fetchDatasets}>
            刷新
          </Button>
        </Col>
      </Row>

      <Row>
        <Col md={12}>
          <Table striped bordered hover>
            <thead>
              <tr>
                <th>GEO ID</th>
                <th>标题</th>
                <th>组织类型</th>
                <th>肿瘤类型</th>
                <th>样本数</th>
                <th>基因数</th>
                <th>发表年份</th>
                <th>操作</th>
              </tr>
            </thead>
            <tbody>
              {datasets.map(dataset => (
                <tr key={dataset.id}>
                  <td>{dataset.geo_id}</td>
                  <td>{dataset.title}</td>
                  <td>{dataset.tissue_type}</td>
                  <td>{dataset.tumor_type}</td>
                  <td>{dataset.n_samples}</td>
                  <td>{dataset.n_genes}</td>
                  <td>{dataset.publication_year}</td>
                  <td>
                    <Button
                      variant="outline-primary"
                      size="sm"
                      as={Link}
                      to={`/datasets/${dataset.geo_id}`}
                    >
                      查看详情
                    </Button>
                  </td>
                </tr>
              ))}
            </tbody>
          </Table>
        </Col>
      </Row>

      <Row className="mt-4">
        <Col md={12} className="d-flex justify-content-center">
          <Pagination>
            <Pagination.Prev
              disabled={currentPage === 1}
              onClick={() => setCurrentPage(currentPage - 1)}
            />
            {Array.from({ length: totalPages }, (_, i) => i + 1).map(page => (
              <Pagination.Item
                key={page}
                active={page === currentPage}
                onClick={() => setCurrentPage(page)}
              >
                {page}
              </Pagination.Item>
            ))}
            <Pagination.Next
              disabled={currentPage === totalPages}
              onClick={() => setCurrentPage(currentPage + 1)}
            />
          </Pagination>
        </Col>
      </Row>
    </Container>
  );
}

// 数据集详情页面组件
function DatasetDetailPage() {
  const { geoId } = useParams();
  const [dataset, setDataset] = useState(null);
  const [samples, setSamples] = useState([]);
  const [genes, setGenes] = useState([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('overview');

  useEffect(() => {
    fetchDatasetDetail();
  }, [geoId]);

  const fetchDatasetDetail = async () => {
    try {
      setLoading(true);
      const [datasetRes, samplesRes, genesRes] = await Promise.all([
        axios.get(`${API_BASE_URL}/datasets/${geoId}`),
        axios.get(`${API_BASE_URL}/datasets/${geoId}/samples`),
        axios.get(`${API_BASE_URL}/datasets/${geoId}/genes`)
      ]);
      
      setDataset(datasetRes.data);
      setSamples(samplesRes.data.samples);
      setGenes(genesRes.data.genes);
    } catch (error) {
      console.error('Error fetching dataset detail:', error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <Container className="text-center py-5">
        <Spinner animation="border" role="status">
          <span className="visually-hidden">Loading...</span>
        </Spinner>
      </Container>
    );
  }

  if (!dataset) {
    return (
      <Container className="py-5">
        <Alert variant="danger">数据集未找到</Alert>
      </Container>
    );
  }

  return (
    <Container className="py-5">
      <Row className="mb-4">
        <Col md={12}>
          <h2>{dataset.title}</h2>
          <p className="text-muted">GEO ID: {dataset.geo_id}</p>
        </Col>
      </Row>

      <Tabs activeKey={activeTab} onSelect={setActiveTab}>
        <Tab eventKey="overview" title="概览">
          <Row className="mt-4">
            <Col md={6}>
              <Card>
                <Card.Header>
                  <h5>基本信息</h5>
                </Card.Header>
                <Card.Body>
                  <Table borderless>
                    <tbody>
                      <tr>
                        <td><strong>组织类型:</strong></td>
                        <td>{dataset.tissue_type}</td>
                      </tr>
                      <tr>
                        <td><strong>肿瘤类型:</strong></td>
                        <td>{dataset.tumor_type}</td>
                      </tr>
                      <tr>
                        <td><strong>测序平台:</strong></td>
                        <td>{dataset.platform}</td>
                      </tr>
                      <tr>
                        <td><strong>样本数量:</strong></td>
                        <td>{dataset.n_samples}</td>
                      </tr>
                      <tr>
                        <td><strong>基因数量:</strong></td>
                        <td>{dataset.n_genes}</td>
                      </tr>
                      <tr>
                        <td><strong>发表年份:</strong></td>
                        <td>{dataset.publication_year}</td>
                      </tr>
                      <tr>
                        <td><strong>参考文献:</strong></td>
                        <td>
                          {dataset.reference_pmid && (
                            <a
                              href={`https://pubmed.ncbi.nlm.nih.gov/${dataset.reference_pmid}/`}
                              target="_blank"
                              rel="noopener noreferrer"
                            >
                              PMID: {dataset.reference_pmid}
                            </a>
                          )}
                        </td>
                      </tr>
                    </tbody>
                  </Table>
                </Card.Body>
              </Card>
            </Col>
            <Col md={6}>
              <Card>
                <Card.Header>
                  <h5>样本统计</h5>
                </Card.Header>
                <Card.Body>
                  <Table borderless>
                    <tbody>
                      <tr>
                        <td><strong>实际样本数:</strong></td>
                        <td>{dataset.sample_stats?.total_samples}</td>
                      </tr>
                      <tr>
                        <td><strong>肿瘤亚型:</strong></td>
                        <td>{dataset.sample_stats?.tumor_subtypes}</td>
                      </tr>
                      <tr>
                        <td><strong>分级:</strong></td>
                        <td>{dataset.sample_stats?.grades}</td>
                      </tr>
                      <tr>
                        <td><strong>分期:</strong></td>
                        <td>{dataset.sample_stats?.stages}</td>
                      </tr>
                      <tr>
                        <td><strong>平均年龄:</strong></td>
                        <td>{dataset.sample_stats?.avg_age?.toFixed(1)}</td>
                      </tr>
                      <tr>
                        <td><strong>性别分布:</strong></td>
                        <td>{dataset.sample_stats?.genders}</td>
                      </tr>
                    </tbody>
                  </Table>
                </Card.Body>
              </Card>
            </Col>
          </Row>
        </Tab>

        <Tab eventKey="samples" title="样本信息">
          <Row className="mt-4">
            <Col md={12}>
              <Table striped bordered hover>
                <thead>
                  <tr>
                    <th>样本ID</th>
                    <th>样本名称</th>
                    <th>肿瘤类型</th>
                    <th>分级</th>
                    <th>分期</th>
                    <th>年龄</th>
                    <th>性别</th>
                    <th>生存状态</th>
                    <th>生存时间</th>
                  </tr>
                </thead>
                <tbody>
                  {samples.map(sample => (
                    <tr key={sample.id}>
                      <td>{sample.sample_id}</td>
                      <td>{sample.sample_name}</td>
                      <td>{sample.tumor_type}</td>
                      <td>{sample.grade}</td>
                      <td>{sample.stage}</td>
                      <td>{sample.age}</td>
                      <td>{sample.gender}</td>
                      <td>{sample.survival_status}</td>
                      <td>{sample.survival_time}</td>
                    </tr>
                  ))}
                </tbody>
              </Table>
            </Col>
          </Row>
        </Tab>

        <Tab eventKey="genes" title="基因列表">
          <Row className="mt-4">
            <Col md={12}>
              <Table striped bordered hover>
                <thead>
                  <tr>
                    <th>基因ID</th>
                    <th>基因符号</th>
                    <th>基因名称</th>
                    <th>染色体</th>
                    <th>基因类型</th>
                    <th>描述</th>
                  </tr>
                </thead>
                <tbody>
                  {genes.map(gene => (
                    <tr key={gene.gene_id}>
                      <td>{gene.gene_id}</td>
                      <td>{gene.gene_symbol}</td>
                      <td>{gene.gene_name}</td>
                      <td>{gene.chromosome}</td>
                      <td>{gene.gene_type}</td>
                      <td>{gene.description}</td>
                    </tr>
                  ))}
                </tbody>
              </Table>
            </Col>
          </Row>
        </Tab>
      </Tabs>
    </Container>
  );
}

// 分析页面组件
function AnalysisPage() {
  const [datasets, setDatasets] = useState([]);
  const [selectedDataset, setSelectedDataset] = useState('');
  const [analysisType, setAnalysisType] = useState('differential_expression');
  const [analysisParams, setAnalysisParams] = useState({});
  const [results, setResults] = useState(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    fetchDatasets();
  }, []);

  const fetchDatasets = async () => {
    try {
      const response = await axios.get(`${API_BASE_URL}/datasets`);
      setDatasets(response.data.datasets);
    } catch (error) {
      console.error('Error fetching datasets:', error);
    }
  };

  const runAnalysis = async () => {
    try {
      setLoading(true);
      const params = {
        dataset_id: selectedDataset,
        ...analysisParams
      };

      let endpoint = '';
      if (analysisType === 'differential_expression') {
        endpoint = '/analysis/differential_expression';
      } else if (analysisType === 'survival') {
        endpoint = '/analysis/survival';
      }

      const response = await axios.post(`${API_BASE_URL}${endpoint}`, params);
      setResults(response.data);
    } catch (error) {
      console.error('Error running analysis:', error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <Container className="py-5">
      <Row className="mb-4">
        <Col md={12}>
          <h2>数据分析</h2>
        </Col>
      </Row>

      <Row>
        <Col md={6}>
          <Card>
            <Card.Header>
              <h5>分析参数设置</h5>
            </Card.Header>
            <Card.Body>
              <Form.Group className="mb-3">
                <Form.Label>选择数据集</Form.Label>
                <Form.Select
                  value={selectedDataset}
                  onChange={(e) => setSelectedDataset(e.target.value)}
                >
                  <option value="">请选择数据集</option>
                  {datasets.map(dataset => (
                    <option key={dataset.id} value={dataset.id}>
                      {dataset.geo_id} - {dataset.title}
                    </option>
                  ))}
                </Form.Select>
              </Form.Group>

              <Form.Group className="mb-3">
                <Form.Label>分析类型</Form.Label>
                <Form.Select
                  value={analysisType}
                  onChange={(e) => setAnalysisType(e.target.value)}
                >
                  <option value="differential_expression">差异表达分析</option>
                  <option value="survival">生存分析</option>
                  <option value="pathway">通路分析</option>
                </Form.Select>
              </Form.Group>

              {analysisType === 'differential_expression' && (
                <>
                  <Form.Group className="mb-3">
                    <Form.Label>比较组1</Form.Label>
                    <Form.Control
                      type="text"
                      placeholder="例如: Normal"
                      value={analysisParams.group1 || ''}
                      onChange={(e) => setAnalysisParams(prev => ({
                        ...prev,
                        group1: e.target.value
                      }))}
                    />
                  </Form.Group>
                  <Form.Group className="mb-3">
                    <Form.Label>比较组2</Form.Label>
                    <Form.Control
                      type="text"
                      placeholder="例如: Tumor"
                      value={analysisParams.group2 || ''}
                      onChange={(e) => setAnalysisParams(prev => ({
                        ...prev,
                        group2: e.target.value
                      }))}
                    />
                  </Form.Group>
                </>
              )}

              {analysisType === 'survival' && (
                <Form.Group className="mb-3">
                  <Form.Label>基因符号</Form.Label>
                  <Form.Control
                    type="text"
                    placeholder="例如: TP53"
                    value={analysisParams.gene_symbol || ''}
                    onChange={(e) => setAnalysisParams(prev => ({
                      ...prev,
                      gene_symbol: e.target.value
                    }))}
                  />
                </Form.Group>
              )}

              <Button
                variant="primary"
                onClick={runAnalysis}
                disabled={loading || !selectedDataset}
              >
                {loading ? '分析中...' : '开始分析'}
              </Button>
            </Card.Body>
          </Card>
        </Col>

        <Col md={6}>
          <Card>
            <Card.Header>
              <h5>分析结果</h5>
            </Card.Header>
            <Card.Body>
              {results ? (
                <div>
                  <Alert variant="success">
                    分析任务已创建，任务ID: {results.task_id}
                  </Alert>
                  <p>状态: {results.status}</p>
                  <p>{results.message}</p>
                </div>
              ) : (
                <p className="text-muted">请先运行分析</p>
              )}
            </Card.Body>
          </Card>
        </Col>
      </Row>
    </Container>
  );
}

// 统计页面组件
function StatisticsPage() {
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchStatistics();
  }, []);

  const fetchStatistics = async () => {
    try {
      const response = await axios.get(`${API_BASE_URL}/statistics/overview`);
      setStats(response.data);
    } catch (error) {
      console.error('Error fetching statistics:', error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <Container className="text-center py-5">
        <Spinner animation="border" role="status">
          <span className="visually-hidden">Loading...</span>
        </Spinner>
      </Container>
    );
  }

  return (
    <Container className="py-5">
      <Row className="mb-4">
        <Col md={12}>
          <h2>数据库统计</h2>
        </Col>
      </Row>

      <Row>
        <Col md={6}>
          <Card>
            <Card.Header>
              <h5>组织类型分布</h5>
            </Card.Header>
            <Card.Body>
              <BarChart width={400} height={300} data={stats?.tissue_types || []}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="tissue_type" />
                <YAxis />
                <Tooltip />
                <Bar dataKey="count" fill="#8884d8" />
              </BarChart>
            </Card.Body>
          </Card>
        </Col>
        <Col md={6}>
          <Card>
            <Card.Header>
              <h5>肿瘤类型分布</h5>
            </Card.Header>
            <Card.Body>
              <PieChart width={400} height={300}>
                <Pie
                  data={stats?.tumor_types || []}
                  dataKey="count"
                  nameKey="tumor_type"
                  cx="50%"
                  cy="50%"
                  outerRadius={80}
                  fill="#8884d8"
                  label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}
                />
                <Tooltip />
              </PieChart>
            </Card.Body>
          </Card>
        </Col>
      </Row>

      <Row className="mt-4">
        <Col md={12}>
          <Card>
            <Card.Header>
              <h5>发表年份趋势</h5>
            </Card.Header>
            <Card.Body>
              <LineChart width={800} height={300} data={stats?.publication_years || []}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="publication_year" />
                <YAxis />
                <Tooltip />
                <Legend />
                <Line type="monotone" dataKey="count" stroke="#8884d8" />
              </LineChart>
            </Card.Body>
          </Card>
        </Col>
      </Row>
    </Container>
  );
}

export default App;
