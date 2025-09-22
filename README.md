# NETA: Neuroendocrine Tumor Atlas

## 项目简介

NETA (Neuroendocrine Tumor Atlas) 是一个专注于泛神经内分泌癌的Bulk RNA-seq数据库和分析平台。本项目整合了来自GEO数据库的真实RNA-seq数据，为神经内分泌肿瘤研究提供全面的转录组分析工具。

## 主要特性

- **真实数据**: 基于GEO数据库的真实RNA-seq数据，确保研究结果的可靠性和可重现性
- **专业分析**: 采用DESeq2进行差异表达分析，生成SCI期刊质量的图表和统计结果
- **开放获取**: 所有分析结果和原始数据均可免费下载，支持学术研究和临床应用
- **多语言支持**: 提供中英文双语界面
- **交互式可视化**: 提供火山图、MA图、PCA图和热图等多种可视化方式

## 数据集概览

目前数据库包含15个神经内分泌肿瘤相关的RNA-seq数据集，涵盖：

- **组织类型**: 胰腺、肺、胃肠道、前列腺等
- **肿瘤类型**: 胰腺NET、小细胞肺癌(SCLC)、胃肠道NET、前列腺神经内分泌癌等
- **样本总数**: 1,247个样本
- **检测基因**: 27,363个基因

## 已分析数据集

### GSE182407: Reciprocal YAP1 loss and INSM1 expression in neuroendocrine prostate cancer

- **样本数**: 24个样本
- **细胞系**: LNCaP, DU145, NCI-H660
- **分析结果**: 
  - 显著差异基因: 1,487个
  - 上调基因: 772个
  - 下调基因: 715个
- **GEO链接**: https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE182407

## 技术架构

### 前端
- **框架**: HTML5 + CSS3 + JavaScript
- **图表库**: Chart.js
- **样式**: Bootstrap 5
- **部署**: GitHub Pages

### 后端分析
- **语言**: R
- **分析工具**: DESeq2, GEOquery
- **可视化**: ggplot2, EnhancedVolcano, pheatmap

### 数据管理
- **版本控制**: Git + Git LFS
- **数据存储**: GitHub Repository
- **文件格式**: CSV, PNG, PDF

## 使用方法

### 在线访问
访问 [NETA GitHub Pages](https://max-yuan-22.github.io/NETA/) 使用在线平台。

### 本地部署
```bash
# 克隆仓库
git clone https://github.com/Max-YUAN-22/NETA.git
cd NETA

# 启动本地服务器
python -m http.server 8000
# 或使用Node.js
npx serve docs
```

### 数据分析
```bash
# 进入R脚本目录
cd R_scripts

# 运行数据下载脚本
Rscript download_useful_datasets.R

# 运行数据合并脚本
Rscript merge_gse182407_final.R

# 运行DESeq2分析
Rscript deseq2_gse182407_fixed.R
```

## 数据质量标准

所有数据集均符合以下质量标准：

- ✅ **RNA-seq数据**: 100%为Bulk RNA-seq数据
- ✅ **生物学重复**: 每组至少3个生物学重复
- ✅ **原始计数**: 提供原始计数矩阵
- ✅ **野生型样本**: 无基因干预的对照样本
- ✅ **数据完整性**: 完整的样本信息和实验设计

## 引用信息

如果您在研究中使用了NETA数据库，请引用：

```bibtex
@software{neta2024,
  title={NETA: Neuroendocrine Tumor Atlas},
  author={Yuan, Max},
  year={2024},
  url={https://github.com/Max-YUAN-22/NETA},
  note={Pan-neuroendocrine cancer Bulk RNA-seq database and analysis platform}
}
```

## 相关论文

- **GSE182407**: Reciprocal YAP1 loss and INSM1 expression in neuroendocrine prostate cancer. PMID: 34431104
- **GSE73338**: Pancreatic neuroendocrine tumors RNA-seq analysis. PMID: 26340334
- **GSE98894**: Gastrointestinal neuroendocrine neoplasms comprehensive analysis. PMID: 28514442

## 贡献指南

我们欢迎社区贡献！请遵循以下步骤：

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

## 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 联系方式

- **项目维护者**: Max Yuan
- **邮箱**: your-email@example.com
- **GitHub**: [@Max-YUAN-22](https://github.com/Max-YUAN-22)
- **项目主页**: https://github.com/Max-YUAN-22/NETA

## 致谢

感谢以下开源项目和数据库：

- [GEO Database](https://www.ncbi.nlm.nih.gov/geo/) - 基因表达数据
- [DESeq2](https://bioconductor.org/packages/DESeq2/) - 差异表达分析
- [GEOquery](https://bioconductor.org/packages/GEOquery/) - GEO数据获取
- [Chart.js](https://www.chartjs.org/) - 数据可视化
- [Bootstrap](https://getbootstrap.com/) - 前端框架

## 更新日志

### v1.0.0 (2024-01-XX)
- 初始版本发布
- 集成15个神经内分泌肿瘤数据集
- 完成GSE182407的DESeq2分析
- 实现中英文双语界面
- 部署到GitHub Pages

---

**NETA项目 | 神经内分泌肿瘤研究平台**  
*连接神经内分泌肿瘤生物学与计算创新*