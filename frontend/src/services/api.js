// API服务配置
export const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:5000/api';
// 使用相对路径，便于在 GitHub Pages (项目子路径) 下正常加载
const FALLBACK_BASE = 'data';

async function fetchWithFallback(primaryUrl, fallbackUrl, init) {
  try {
    const res = await fetch(primaryUrl, init);
    if (res && res.ok) return res;
  } catch (_) {
    // ignore and try fallback
  }
  return fetch(fallbackUrl, init);
}

// API调用函数
export const api = {
  // 健康检查
  healthCheck: () => fetch(`${API_BASE_URL}/health`),
  
  // 数据集相关
  getDatasets: (page = 1, perPage = 20) => 
    fetchWithFallback(
      `${API_BASE_URL}/datasets?page=${page}&per_page=${perPage}`,
      `${FALLBACK_BASE}/datasets.json`
    ),
  
  getDatasetDetail: (id) => 
    fetch(`${API_BASE_URL}/datasets/${id}`),
  
  // 数据集筛选和搜索
  filterDatasets: (params) => 
    fetchWithFallback(
      `${API_BASE_URL}/datasets/filter?${params}`,
      `${FALLBACK_BASE}/datasets.json`
    ),
  
  searchDatasets: (query, limit = 20) => 
    fetchWithFallback(
      `${API_BASE_URL}/datasets/search?q=${query}&limit=${limit}`,
      `${FALLBACK_BASE}/datasets.json`
    ),
  
  getDatasetStatistics: () => 
    fetchWithFallback(
      `${API_BASE_URL}/datasets/statistics`,
      `${FALLBACK_BASE}/stats.json`
    ),
  
  // 统计信息
  getStatistics: () => 
    fetch(`${API_BASE_URL}/statistics/overview`),
  
  // 基因查询
  searchGenes: (query, limit = 50) => 
    fetch(`${API_BASE_URL}/genes/search?q=${query}&limit=${limit}`),
  
  // 分析功能
  runDifferentialExpression: (data) => 
    fetch(`${API_BASE_URL}/analysis/differential_expression`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data)
    }),
  
  runPCAAnalysis: (data) => 
    fetch(`${API_BASE_URL}/analysis/pca`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data)
    }),
  
  runEnrichmentAnalysis: (data) => 
    fetch(`${API_BASE_URL}/analysis/enrichment`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data)
    }),
  
  // 批量分析
  runBatchAnalysis: (data) => 
    fetch(`${API_BASE_URL}/analysis/batch`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data)
    })
};
