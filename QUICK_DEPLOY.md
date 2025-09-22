# 🚀 NETA GitHub 快速部署指南

## 📋 部署前准备

### 1. **安装必要工具**
```bash
# 安装GitHub CLI
brew install gh  # macOS
# 或
sudo apt-get install gh  # Ubuntu

# 安装Git LFS
brew install git-lfs  # macOS
# 或
sudo apt-get install git-lfs  # Ubuntu
```

### 2. **登录GitHub**
```bash
# 登录GitHub CLI
gh auth login

# 选择认证方式：
# 1. Login with a web browser
# 2. Paste an authentication token
```

## 🎯 一键部署

### 方法1: 使用自动部署脚本（推荐）
```bash
# 进入NETA项目目录
cd /Users/Apple/Desktop/pcatools/NETA

# 运行自动部署脚本
./scripts/deploy_to_github.sh
```

### 方法2: 手动部署
```bash
# 1. 创建GitHub仓库
gh repo create neta-project --public --description "NETA: Neuroendocrine Tumor Atlas"

# 2. 初始化Git
git init
git remote add origin https://github.com/yourusername/neta-project.git

# 3. 配置Git LFS
git lfs install
git lfs track "*.rds" "*.csv" "*.tsv" "*.zip" "*.gz"

# 4. 添加文件
git add .
git commit -m "Initial NETA project deployment"

# 5. 推送到GitHub
git push -u origin main

# 6. 启用GitHub Pages
gh api repos/yourusername/neta-project/pages --method POST \
  --field source[type]=branch \
  --field source[branch]=main \
  --field source[path]=/docs
```

## 🌐 访问您的NETA网站

部署完成后，您可以通过以下地址访问：

- **GitHub仓库**: `https://github.com/yourusername/neta-project`
- **GitHub Pages**: `https://yourusername.github.io/neta-project`
- **前端界面**: `https://yourusername.github.io/neta-project/docs/`

## 💾 数据存储策略

### 1. **小文件 (< 100MB)**
- 直接存储在Git仓库中
- 自动版本控制
- 全球CDN加速

### 2. **大文件 (> 100MB)**
- 使用Git LFS存储
- 云端存储，本地节省空间
- 按需下载

### 3. **超大文件 (> 1GB)**
- 使用GitHub Releases
- 创建数据发布包
- 版本化管理

## 📊 存储空间对比

| 存储方式 | 本地占用 | 云端存储 | 访问速度 | 成本 |
|---------|---------|---------|---------|------|
| 本地存储 | 100% | 0% | 快 | 高 |
| GitHub LFS | 5% | 95% | 中等 | 免费 |
| GitHub Releases | 0% | 100% | 中等 | 免费 |

## 🔧 数据上传示例

### 上传RNA-seq数据
```bash
# 1. 准备数据文件
mkdir -p data/raw/GSE73338
cp your_rna_seq_data.csv data/raw/GSE73338/

# 2. 添加到Git LFS
git lfs track "data/raw/**"
git add data/raw/GSE73338/

# 3. 提交并推送
git commit -m "Add GSE73338 RNA-seq data"
git push origin main
```

### 创建数据发布
```bash
# 1. 创建数据包
tar -czf neta_data_v1.0.tar.gz data/processed/

# 2. 创建GitHub Release
gh release create v1.0 neta_data_v1.0.tar.gz \
  --title "NETA Data Release v1.0" \
  --notes "Initial release with 8 neuroendocrine tumor datasets"
```

## 🎨 自定义配置

### 修改GitHub用户名
```bash
# 在部署脚本中修改
GITHUB_USERNAME="your-actual-username"
```

### 修改仓库名称
```bash
# 在部署脚本中修改
REPO_NAME="your-custom-name"
```

### 修改网站域名
```bash
# 在GitHub Pages设置中添加自定义域名
# Settings > Pages > Custom domain
```

## 🚨 常见问题

### Q: Git LFS配额不足怎么办？
A: 
- 免费用户有1GB LFS存储
- 可以升级到付费计划
- 或使用GitHub Releases存储大文件

### Q: 数据上传失败怎么办？
A: 
- 检查文件大小限制（100MB）
- 确保网络连接稳定
- 使用`git lfs pull`重新下载

### Q: GitHub Pages无法访问？
A: 
- 检查仓库设置中的Pages配置
- 确保docs文件夹存在
- 等待几分钟让CDN更新

## 📈 性能优化

### 1. **数据压缩**
```bash
# 压缩CSV文件
gzip data/processed/*.csv

# 压缩元数据
tar -czf metadata.tar.gz data/metadata/
```

### 2. **增量更新**
```bash
# 只上传新增数据
git add data/processed/new_datasets/
git commit -m "Add new datasets"
git push origin main
```

### 3. **CDN加速**
- GitHub Pages自动使用CDN
- 全球多个节点加速访问
- 无需额外配置

## 🎉 部署成功！

恭喜！您的NETA项目已成功部署到GitHub。

### 下一步建议：
1. **测试网站功能**：访问GitHub Pages链接
2. **上传真实数据**：使用Git LFS上传RNA-seq数据
3. **邀请团队成员**：添加协作者权限
4. **设置自动化**：配置GitHub Actions
5. **收集用户反馈**：使用GitHub Issues

### 技术支持：
- 📧 邮箱：your-email@example.com
- 🐛 问题报告：GitHub Issues
- 📖 文档：项目README.md
- 💬 讨论：GitHub Discussions

---

**🎯 目标达成**：本地存储节省90%+，数据云端存储，24/7全球访问！
