import React from 'react';
import { BrowserRouter as Router, Routes, Route, Link } from 'react-router-dom';
import { Navbar, Nav, Container } from 'react-bootstrap';
import 'bootstrap/dist/css/bootstrap.min.css';

// 页面组件
import HomePage from './pages/HomePage';
import DatasetsPage from './pages/DatasetsPage';
import GeneQueryPage from './pages/GeneQueryPage';
import PCAPage from './pages/PCAPage';
import VolcanoPage from './pages/VolcanoPage';
import HeatmapPage from './pages/HeatmapPage';

// API服务
import { API_BASE_URL } from './services/api';

function App() {
  return (
    <Router>
      <div className="App">
        <Navbar bg="dark" variant="dark" expand="lg">
          <Container>
            <Navbar.Brand as={Link} to="/">
              🧬 NETA
            </Navbar.Brand>
            <Navbar.Toggle aria-controls="basic-navbar-nav" />
            <Navbar.Collapse id="basic-navbar-nav">
              <Nav className="me-auto">
                <Nav.Link as={Link} to="/">首页</Nav.Link>
                <Nav.Link as={Link} to="/datasets">数据集</Nav.Link>
                <Nav.Link as={Link} to="/genes">基因查询</Nav.Link>
                <Nav.Link as={Link} to="/pca">PCA分析</Nav.Link>
                <Nav.Link as={Link} to="/volcano">火山图</Nav.Link>
                <Nav.Link as={Link} to="/heatmap">热图</Nav.Link>
              </Nav>
            </Navbar.Collapse>
          </Container>
        </Navbar>

        <Container className="mt-4">
          <Routes>
            <Route path="/" element={<HomePage />} />
            <Route path="/datasets" element={<DatasetsPage />} />
            <Route path="/genes" element={<GeneQueryPage />} />
            <Route path="/pca" element={<PCAPage />} />
            <Route path="/volcano" element={<VolcanoPage />} />
            <Route path="/heatmap" element={<HeatmapPage />} />
          </Routes>
        </Container>
      </div>
    </Router>
  );
}

export default App;
