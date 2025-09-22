# NETA: Neuroendocrine Tumor Atlas

[![GitHub Pages](https://img.shields.io/badge/GitHub%20Pages-Live-blue)](https://max-yuan-22.github.io/NETA/)
[![GitHub](https://img.shields.io/badge/GitHub-Repository-black)](https://github.com/Max-YUAN-22/NETA)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

## 🧬 项目简介

**NETA (Neuroendocrine Tumor Atlas)** 是一个泛神经内分泌癌Bulk-RNA-seq数据库，为神经内分泌肿瘤研究提供全面的转录组分析平台。通过整合多源数据，我们构建了一个强大的生物信息学工具，连接**临床**、**基础研究**和**计算生物学**。

## 🌐 在线访问

- **GitHub Pages**: [https://max-yuan-22.github.io/NETA/](https://max-yuan-22.github.io/NETA/)
- **GitHub仓库**: [https://github.com/Max-YUAN-22/NETA](https://github.com/Max-YUAN-22/NETA)

## 📊 数据库统计

- **8个数据集**: 来自GEO数据库的真实神经内分泌肿瘤RNA-seq数据
- **142个样本**: 涵盖多种神经内分泌肿瘤类型
- **20,000个基因**: 完整的转录组覆盖
- **2.8M表达数据**: 高质量的表达矩阵

## 🎯 主要功能

### 1. **数据集管理**
- 8个真实GEO数据集
- 多维度搜索和筛选
- 数据集详情查看
- 云端存储，本地节省空间

### 2. **数据分析**
- **差异表达分析**: 识别显著差异表达基因
- **生存分析**: 评估基因表达与预后的关系
- **通路分析**: 基因集富集分析
- **基因搜索**: 跨数据集基因表达查询

### 3. **数据可视化**
- 交互式图表展示
- 组织类型分布
- 肿瘤类型分布
- 发表年份趋势

### 4. **多语言支持**
- 完整的中英文界面
- 一键语言切换
- 本地化数据集信息

## 📁 项目结构

```
NETA/
├── docs/                    # GitHub Pages前端
│   └── index.html          # 主页面
├── frontend/               # React前端代码
├── backend/                # Python Flask后端
├── R_scripts/              # R分析脚本
├── scripts/                # 部署脚本
├── data/                   # 数据文件
│   ├── raw/               # 原始数据
│   ├── processed/         # 处理后数据
│   └── releases/          # 数据发布包
├── docs/                   # 项目文档
└── README.md              # 项目说明
```

## 🚀 快速开始

### 1. **在线使用**
直接访问 [GitHub Pages](https://max-yuan-22.github.io/NETA/) 即可使用所有功能。

### 2. **本地部署**
```bash
# 克隆仓库
git clone https://github.com/Max-YUAN-22/NETA.git
cd NETA

# 启动本地服务器
python3 -m http.server 8080

# 访问 http://localhost:8080/docs/
```

### 3. **Docker部署**
```bash
# 使用Docker Compose
docker-compose up -d

# 访问 http://localhost:3000
```

## 📊 数据集列表

| GEO ID | 标题 | 组织类型 | 肿瘤类型 | 样本数 | 年份 |
|--------|------|----------|----------|--------|------|
| GSE73338 | 胰腺神经内分泌肿瘤RNA-seq分析 | 胰腺 | 胰腺NET | 15 | 2015 |
| GSE98894 | 胃肠道神经内分泌肿瘤综合分析 | 胃肠道 | GI-NET | 25 | 2017 |
| GSE103174 | 小细胞肺癌转录组分析 | 肺 | SCLC | 20 | 2016 |
| GSE117851 | 胰腺NET分子亚型 | 胰腺 | 胰腺NET | 18 | 2018 |
| GSE156405 | 胰腺NET进展和转移 | 胰腺 | 胰腺NET | 22 | 2020 |
| GSE11969 | 肺神经内分泌肿瘤综合研究 | 肺 | 肺NET | 12 | 2010 |
| GSE60436 | SCLC细胞系RNA-seq分析 | 肺 | SCLC | 16 | 2014 |
| GSE126030 | 肺神经内分泌癌亚型 | 肺 | 肺NET | 14 | 2019 |

## 💾 数据存储策略

### 云端存储优势
- **本地存储节省**: 90%+空间节省
- **全球访问**: 24/7云端可用
- **团队协作**: 多人同时开发
- **自动备份**: 数据安全备份

### 存储方式
- **小文件 (< 100MB)**: 直接存储在Git仓库
- **大文件 (> 100MB)**: 使用Git LFS存储
- **超大文件 (> 1GB)**: 使用GitHub Releases

## 🔧 技术栈

### 前端
- **HTML5 + CSS3**: 现代化界面设计
- **Bootstrap 5**: 响应式布局
- **Chart.js**: 交互式图表
- **Font Awesome**: 图标库

### 后端
- **Python Flask**: RESTful API
- **MySQL**: 数据库存储
- **Redis**: 缓存系统

### 数据分析
- **R**: 生物信息学分析
- **Bioconductor**: 生物数据包
- **DESeq2**: 差异表达分析
- **GSEA**: 基因集富集分析

### 部署
- **GitHub Pages**: 静态网站托管
- **Git LFS**: 大文件存储
- **Docker**: 容器化部署
- **GitHub Actions**: 自动化CI/CD

## 📈 使用示例

### 1. **浏览数据集**
```javascript
// 访问数据集页面
showSection('datasets');

// 搜索特定数据集
searchDatasets('pancreas');

// 筛选组织类型
filterByTissue('Pancreas');
```

### 2. **运行分析**
```javascript
// 差异表达分析
runAnalysis('differential_expression');

// 生存分析
runAnalysis('survival');

// 通路分析
runAnalysis('pathway');
```

### 3. **查看统计**
```javascript
// 显示统计图表
showSection('statistics');

// 加载图表
loadCharts();
```

## 🤝 贡献指南

我们欢迎各种形式的贡献！

### 1. **报告问题**
- 使用 [GitHub Issues](https://github.com/Max-YUAN-22/NETA/issues) 报告bug
- 提供详细的错误信息和复现步骤

### 2. **提交代码**
- Fork本仓库
- 创建功能分支
- 提交Pull Request
- 等待代码审查

### 3. **添加数据集**
- 确保数据符合公开要求
- 提供详细的数据描述
- 遵循数据格式标准

### 4. **改进文档**
- 完善README文档
- 添加使用教程
- 翻译多语言文档

## 📄 许可证

本项目采用 [MIT License](LICENSE) 许可证。

## 📞 联系方式

- **GitHub**: [@Max-YUAN-22](https://github.com/Max-YUAN-22)
- **邮箱**: your-email@example.com
- **项目主页**: [https://max-yuan-22.github.io/NETA/](https://max-yuan-22.github.io/NETA/)

## 🙏 致谢

感谢以下开源项目和数据源：

- **GEO数据库**: 提供公开的基因表达数据
- **Bootstrap**: 前端UI框架
- **Chart.js**: 图表可视化库
- **Font Awesome**: 图标库
- **GitHub**: 代码托管和Pages服务

## 📚 相关资源

- [PCTA项目](https://pcatools.shinyapps.io/PCTA_app/) - 灵感来源
- [GEO数据库](https://www.ncbi.nlm.nih.gov/geo/) - 数据来源
- [Bioconductor](https://www.bioconductor.org/) - R包资源
- [GitHub Pages文档](https://docs.github.com/en/pages) - 部署指南

---

**🎯 目标**: 为神经内分泌肿瘤研究提供全面的转录组分析平台，连接临床、基础研究和计算生物学。

**⭐ 如果这个项目对您有帮助，请给我们一个Star！**