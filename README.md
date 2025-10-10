# 🧬 NETA - 泛神经内分泌癌转录组学分析平台

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub Pages](https://img.shields.io/badge/GitHub%20Pages-Deployed-brightgreen)](https://max-yuan-22.github.io/NETA/)
[![Data Quality](https://img.shields.io/badge/Data%20Quality-70%2F100-orange)](https://github.com/Max-YUAN-22/NETA)
[![Real Data](https://img.shields.io/badge/Data-100%25%20Real%20GEO-blue)](https://github.com/Max-YUAN-22/NETA)

> **基于19个真实GEO数据集的神经内分泌癌转录组学分析平台**  
> 提供差异表达分析、PCA分析、富集分析、生存分析等全面的生物信息学功能

## 📊 平台概览

NETA (NeuroEndocrine Tumor Analysis) 是一个专为神经内分泌癌研究设计的现代化转录组学分析平台。我们整合了来自GEO数据库的19个高质量数据集，包含2,196个临床样本和230,219个基因的表达数据，为研究者提供一站式的生物信息学分析服务。

### 🎯 核心特性

- **📈 100%真实数据**: 所有数据均来自GEO数据库，无任何模拟数据
- **🔬 全面分析功能**: 支持差异表达分析、PCA分析、富集分析、生存分析
- **📊 交互式可视化**: 提供火山图、热图、散点图等多种可视化图表
- **🚀 现代化技术**: 基于Flask + React + R的现代化技术栈
- **🌐 在线访问**: 支持GitHub Pages部署，随时随地访问
- **📚 发表就绪**: 具备发表高分论文的所有条件

## 🗂️ 数据统计

| 指标 | 数量 | 说明 |
|------|------|------|
| 数据集 | 19个 | 真实GEO数据集 |
| 样本 | 2,196个 | 临床样本 |
| 基因 | 230,219个 | 全基因组覆盖 |
| 表达记录 | 380万条 | 高质量数据 |
| 组织类型 | 4种 | 胰腺、前列腺、胃肠道、肺 |
| 肿瘤类型 | 6种 | 涵盖主要神经内分泌癌类型 |

## 🏗️ 技术架构

### 后端技术栈
- **Flask**: Python Web框架
- **SQLite**: 轻量级数据库
- **R**: 生物信息学分析引擎
- **Docker**: 容器化部署

### 前端技术栈
- **React**: 现代化用户界面
- **Bootstrap 5**: 响应式设计
- **Recharts**: 数据可视化
- **React Router**: 单页应用路由

### 分析工具
- **DESeq2**: 差异表达分析
- **GEOquery**: GEO数据获取
- **clusterProfiler**: 富集分析
- **survival**: 生存分析
- **ggplot2**: 数据可视化

## 🚀 快速开始

### 在线访问
直接访问 [NETA平台](https://max-yuan-22.github.io/NETA/) 开始使用。

### 本地部署

1. **克隆仓库**
   ```bash
   git clone https://github.com/Max-YUAN-22/NETA.git
   cd NETA
   ```

2. **安装依赖**
   ```bash
   # 后端依赖
   cd backend
   pip install -r requirements.txt
   
   # 前端依赖
   cd ../frontend
   npm install
   ```

3. **导入数据**
   ```bash
   # 导入真实GEO数据
   Rscript R_scripts/import_real_geo_data.R
   ```

4. **启动服务**
   ```bash
   # 启动后端
   cd backend
   python app.py
   
   # 启动前端
   cd ../frontend
   npm start
   ```

## 📖 使用指南

### 1. 数据集浏览
- 访问"数据集"页面查看所有可用的GEO数据集
- 按组织类型、肿瘤类型筛选数据集
- 查看每个数据集的详细信息和样本统计

### 2. 基因查询
- 在"基因查询"页面输入基因符号
- 查看基因在不同数据集中的表达情况
- 生成表达量分布图表

### 3. PCA分析
- 选择数据集进行主成分分析
- 可视化样本在主成分空间的分布
- 识别样本聚类和异常值

### 4. 差异表达分析
- 选择数据集和比较组
- 运行DESeq2差异表达分析
- 生成火山图可视化结果

### 5. 富集分析
- 输入差异表达基因列表
- 运行KEGG/GO富集分析
- 查看富集通路和功能注释

### 6. 生存分析
- 选择有生存信息的数据集
- 运行Kaplan-Meier生存分析
- 生成生存曲线图

## 📊 数据质量报告

我们的数据质量评分：**70/100** ⭐⭐⭐

### 数据完整性
- ✅ 无缺失基因符号
- ✅ 无缺失样本ID
- ✅ 无数据关联不一致
- ✅ 90.14%的表达记录为非零值

### 数据分布
- **组织类型**: 胰腺(8个)、前列腺(4个)、胃肠道(4个)、肺(3个)
- **肿瘤类型**: 胰腺癌(6个)、前列腺癌(4个)、SCLC(3个)等
- **表达数据**: 380万条高质量表达记录

## 🔬 分析功能详解

### 差异表达分析 (DESeq2)
- 基于负二项分布的统计模型
- 多重检验校正 (FDR)
- 可调节的显著性阈值
- 支持多种比较策略

### 主成分分析 (PCA)
- 降维可视化
- 样本聚类分析
- 异常值检测
- 解释方差比例

### 富集分析
- KEGG通路富集
- GO功能富集
- 超几何检验
- 多重检验校正

### 生存分析
- Kaplan-Meier估计
- Log-rank检验
- 风险比计算
- 生存曲线可视化

## 📈 发表潜力

NETA平台具备发表高分论文的所有条件：

### 数据规模
- 19个真实GEO数据集
- 2,196个临床样本
- 230,219个基因
- 380万条表达记录

### 技术创新
- 现代化Web技术栈
- 交互式可视化
- 实时分析功能
- 可重现的研究流程

### 临床相关性
- 涵盖主要神经内分泌癌类型
- 真实临床样本数据
- 多组织类型比较
- 生存分析支持

### 可重现性
- 完整的代码文档
- 标准化的分析流程
- 参数记录和版本控制
- 开源可用

## 🤝 贡献指南

我们欢迎社区贡献！请遵循以下步骤：

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 📞 联系我们

- **GitHub**: [Max-YUAN-22](https://github.com/Max-YUAN-22)
- **项目地址**: [NETA](https://github.com/Max-YUAN-22/NETA)
- **在线平台**: [NETA平台](https://max-yuan-22.github.io/NETA/)

## 🙏 致谢

感谢以下开源项目和服务：

- [GEO数据库](https://www.ncbi.nlm.nih.gov/geo/) - 数据来源
- [Bioconductor](https://www.bioconductor.org/) - R包生态
- [React](https://reactjs.org/) - 前端框架
- [Flask](https://flask.palletsprojects.com/) - 后端框架
- [Bootstrap](https://getbootstrap.com/) - UI框架

## 📚 参考文献

如果您在研究中使用了NETA平台，请引用：

```bibtex
@software{neta2024,
  title={NETA: A Comprehensive NeuroEndocrine Tumor Analysis Platform},
  author={Max-YUAN-22},
  year={2024},
  url={https://github.com/Max-YUAN-22/NETA},
  note={Based on 19 real GEO datasets with 2,196 samples and 230,219 genes}
}
```

---

**⭐ 如果这个项目对您有帮助，请给我们一个星标！**