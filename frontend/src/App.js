import React from 'react';
import { BrowserRouter as Router, Routes, Route, Link } from 'react-router-dom';
import { Navbar, Nav, Container } from 'react-bootstrap';
import 'bootstrap/dist/css/bootstrap.min.css';
import 'bootstrap-icons/font/bootstrap-icons.css';
import './index.css';

// 页面组件
import HomePage from './pages/HomePage';
import DatasetsPage from './pages/DatasetsPage';
import GeneQueryPage from './pages/GeneQueryPage';
import PCAPage from './pages/PCAPage';
import VolcanoPage from './pages/VolcanoPage';
import HeatmapPage from './pages/HeatmapPage';
import UserGuidePage from './pages/UserGuidePage';

// API服务
import { API_BASE_URL } from './services/api';

function App() {
  return (
    <Router>
      <div className="App">
        <Navbar expand="lg" className="navbar fixed-top">
          <Container>
            <Navbar.Brand as={Link} to="/" className="navbar-brand">
              🧬 NETA
            </Navbar.Brand>
            <Navbar.Toggle aria-controls="basic-navbar-nav" />
            <Navbar.Collapse id="basic-navbar-nav">
              <Nav className="me-auto">
                <Nav.Link as={Link} to="/" className="nav-link">
                  <i className="bi bi-house-door me-1"></i>首页
                </Nav.Link>
                <Nav.Link as={Link} to="/datasets" className="nav-link">
                  <i className="bi bi-database me-1"></i>数据集
                </Nav.Link>
                <Nav.Link as={Link} to="/genes" className="nav-link">
                  <i className="bi bi-search me-1"></i>基因查询
                </Nav.Link>
                <Nav.Link as={Link} to="/pca" className="nav-link">
                  <i className="bi bi-graph-up me-1"></i>PCA分析
                </Nav.Link>
                <Nav.Link as={Link} to="/volcano" className="nav-link">
                  <i className="bi bi-graph-up-arrow me-1"></i>火山图
                </Nav.Link>
                <Nav.Link as={Link} to="/heatmap" className="nav-link">
                  <i className="bi bi-grid-3x3-gap me-1"></i>热图
                </Nav.Link>
                <Nav.Link as={Link} to="/guide" className="nav-link">
                  <i className="bi bi-book me-1"></i>用户指南
                </Nav.Link>
              </Nav>
              <Nav>
                <Nav.Link href="https://github.com/Max-YUAN-22/NETA" target="_blank" className="nav-link">
                  <i className="bi bi-github me-1"></i>GitHub
                </Nav.Link>
              </Nav>
            </Navbar.Collapse>
          </Container>
        </Navbar>
        
        <div style={{ marginTop: '80px' }}>
          <Container>
            <Routes>
              <Route path="/" element={<HomePage />} />
              <Route path="/datasets" element={<DatasetsPage />} />
              <Route path="/genes" element={<GeneQueryPage />} />
              <Route path="/pca" element={<PCAPage />} />
              <Route path="/volcano" element={<VolcanoPage />} />
              <Route path="/heatmap" element={<HeatmapPage />} />
              <Route path="/guide" element={<UserGuidePage />} />
            </Routes>
          </Container>
        </div>
      </div>
    </Router>
  );
}

export default App;
