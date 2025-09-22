# NETA GitHub 部署方案

## 🚀 概述

将NETA项目部署到GitHub，实现云端数据存储和前端展示，节省本地存储空间。

## 📁 存储策略

### 1. **代码存储** (GitHub Repository)
```
neta-project/
├── frontend/           # React前端代码
├── backend/           # Python Flask后端
├── R_scripts/         # R分析脚本
├── docs/              # 文档
├── scripts/           # 部署脚本
└── README.md          # 项目说明
```

### 2. **数据存储** (GitHub LFS + Releases)
```
data/
├── raw/               # 原始RNA-seq数据 (Git LFS)
│   ├── GSE73338/
│   ├── GSE98894/
│   └── ...
├── processed/          # 处理后的数据 (Git LFS)
│   ├── expression_matrices/
│   ├── metadata/
│   └── analysis_results/
└── releases/           # 数据发布包 (GitHub Releases)
    ├── neta_v1.0_data.zip
    └── neta_v1.1_data.zip
```

## 🌐 前端展示 (GitHub Pages)

### 访问地址
- **主站**: `https://yourusername.github.io/neta-project`
- **API**: `https://yourusername.github.io/neta-project/api`

### 功能特点
- ✅ 静态前端展示
- ✅ 中英文切换
- ✅ 响应式设计
- ✅ 数据可视化
- ✅ 免费托管

## 📊 数据管理策略

### 1. **Git LFS (Large File Storage)**
```bash
# 安装Git LFS
git lfs install

# 跟踪大文件
git lfs track "*.rds"
git lfs track "*.csv"
git lfs track "*.tsv"
git lfs track "*.zip"
git lfs track "*.gz"

# 添加LFS文件
git add .gitattributes
git add data/
git commit -m "Add RNA-seq data with LFS"
git push origin main
```

### 2. **GitHub Releases**
```bash
# 创建数据发布包
tar -czf neta_data_v1.0.tar.gz data/processed/
gh release create v1.0 neta_data_v1.0.tar.gz -t "NETA Data Release v1.0"
```

### 3. **数据版本控制**
- **v1.0**: 初始8个数据集
- **v1.1**: 添加新数据集
- **v1.2**: 更新分析结果

## 🔄 自动化工作流

### GitHub Actions配置
```yaml
# .github/workflows/deploy.yml
name: Deploy NETA

on:
  push:
    branches: [ main ]
  release:
    types: [ published ]

jobs:
  deploy-frontend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./frontend/build
```

## 💾 存储空间优化

### 1. **数据压缩**
```bash
# 压缩表达矩阵
gzip data/processed/expression_matrices/*.csv

# 压缩元数据
tar -czf data/processed/metadata.tar.gz data/processed/metadata/
```

### 2. **增量更新**
```bash
# 只上传新增数据
git add data/processed/new_datasets/
git commit -m "Add new datasets: GSE123456"
git push origin main
```

### 3. **数据清理**
```bash
# 移除临时文件
rm -rf data/temp/
rm -f data/*.log
```

## 🔧 部署步骤

### 1. **创建GitHub仓库**
```bash
# 在GitHub上创建新仓库: neta-project
git init
git remote add origin https://github.com/yourusername/neta-project.git
```

### 2. **设置Git LFS**
```bash
# 安装Git LFS
brew install git-lfs  # macOS
# 或
sudo apt-get install git-lfs  # Ubuntu

# 初始化LFS
git lfs install
git lfs track "*.rds" "*.csv" "*.tsv" "*.zip" "*.gz"
```

### 3. **上传代码和数据**
```bash
# 添加所有文件
git add .
git commit -m "Initial NETA project with data"
git push -u origin main
```

### 4. **启用GitHub Pages**
1. 进入仓库设置
2. 滚动到"Pages"部分
3. 选择"Deploy from a branch"
4. 选择"main"分支和"/docs"文件夹

## 📈 优势

### 1. **存储优势**
- ✅ 免费存储空间 (1GB LFS + 2GB Releases)
- ✅ 版本控制
- ✅ 数据备份
- ✅ 全球CDN加速

### 2. **协作优势**
- ✅ 多人协作
- ✅ 问题跟踪
- ✅ 代码审查
- ✅ 自动化部署

### 3. **访问优势**
- ✅ 24/7在线访问
- ✅ 无需本地服务器
- ✅ 移动端友好
- ✅ SEO优化

## 🚨 注意事项

### 1. **数据隐私**
- 确保数据符合公开要求
- 遵守GEO数据使用协议
- 保护患者隐私信息

### 2. **存储限制**
- Git LFS: 1GB免费，超出需付费
- GitHub Releases: 2GB免费
- 单个文件: 100MB限制

### 3. **访问速度**
- 首次加载可能较慢
- 建议使用CDN加速
- 考虑数据分片

## 📋 实施计划

### 阶段1: 基础部署 (1-2天)
- [ ] 创建GitHub仓库
- [ ] 设置Git LFS
- [ ] 上传代码和文档
- [ ] 配置GitHub Pages

### 阶段2: 数据上传 (2-3天)
- [ ] 准备数据文件
- [ ] 压缩和优化数据
- [ ] 上传到Git LFS
- [ ] 创建数据发布

### 阶段3: 自动化 (1天)
- [ ] 配置GitHub Actions
- [ ] 设置自动部署
- [ ] 测试工作流
- [ ] 优化性能

### 阶段4: 优化 (持续)
- [ ] 监控存储使用
- [ ] 优化加载速度
- [ ] 用户反馈收集
- [ ] 功能迭代

## 🎯 预期效果

- **存储节省**: 本地存储减少90%+
- **访问便利**: 全球24/7访问
- **协作效率**: 团队协作提升
- **维护成本**: 自动化部署降低维护成本

## 📞 技术支持

如有问题，请参考：
- [GitHub LFS文档](https://docs.github.com/en/repositories/working-with-files/managing-large-files)
- [GitHub Pages文档](https://docs.github.com/en/pages)
- [GitHub Actions文档](https://docs.github.com/en/actions)
