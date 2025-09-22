# NETA项目部署指南

## 项目结构
```
NETA/
├── _config.yml                 # Jekyll配置文件
├── index.md                   # 主页内容
├── README.md                  # 项目说明
├── assets/
│   └── css/
│       └── style.css          # 自定义样式
├── shiny_app/
│   └── app.R                  # Shiny应用主文件
├── R_scripts/
│   ├── install_dependencies.R # 依赖包安装脚本
│   └── data_processing.R     # 数据处理流程
├── data/
│   ├── raw/                   # 原始数据
│   └── processed/             # 处理后数据
└── docs/                      # 文档
```

## 部署步骤

### 1. GitHub Pages部署（网站）

1. **创建GitHub仓库**
   ```bash
   git init
   git add .
   git commit -m "Initial NETA project setup"
   git remote add origin https://github.com/your-username/neta.git
   git push -u origin main
   ```

2. **启用GitHub Pages**
   - 进入仓库设置
   - 选择Pages选项
   - 选择Source为"Deploy from a branch"
   - 选择main分支
   - 网站将在 `https://your-username.github.io/neta/` 可用

### 2. ShinyApps.io部署（应用）

1. **安装rsconnect包**
   ```r
   install.packages("rsconnect")
   ```

2. **配置ShinyApps.io账户**
   ```r
   library(rsconnect)
   rsconnect::setAccountInfo(
     name='your-account-name',
     token='your-token',
     secret='your-secret'
   )
   ```

3. **部署应用**
   ```r
   rsconnect::deployApp(
     appDir = "shiny_app",
     appName = "NETA_app",
     appTitle = "NETA: Neuroendocrine Tumor Atlas"
   )
   ```

### 3. 本地开发环境设置

1. **安装R和RStudio**
   - 下载并安装最新版本的R
   - 下载并安装RStudio

2. **安装依赖包**
   ```r
   source("R_scripts/install_dependencies.R")
   ```

3. **运行Shiny应用**
   ```r
   setwd("shiny_app")
   shiny::runApp()
   ```

### 4. 数据准备

1. **下载神经内分泌肿瘤数据**
   - 从GEO数据库下载相关数据集
   - 从TCGA数据库下载NET相关数据
   - 整理临床和病理信息

2. **运行数据处理流程**
   ```r
   source("R_scripts/data_processing.R")
   # 修改geo_ids为实际的数据集ID
   geo_ids <- c("GSE12345", "GSE67890")
   neta_data <- process_neta_data(geo_ids)
   ```

### 5. 自定义配置

1. **修改_config.yml**
   - 更新repository字段为您的GitHub用户名
   - 修改title和description

2. **更新index.md**
   - 修改联系信息
   - 更新Shiny应用链接
   - 添加您的机构信息

3. **自定义样式**
   - 修改assets/css/style.css中的颜色主题
   - 调整布局和字体

### 6. 高级功能

1. **添加新功能模块**
   - 在shiny_app/app.R中添加新的tabItem
   - 实现相应的server逻辑

2. **集成外部数据库**
   - 连接TCGA数据库
   - 集成GEO数据库查询
   - 添加药物数据库

3. **性能优化**
   - 使用缓存机制
   - 优化大数据集处理
   - 添加进度条

## 维护和更新

### 定期更新
- 更新R包版本
- 添加新的数据集
- 改进用户界面
- 修复bug

### 数据更新
- 定期下载新的GEO数据集
- 更新TCGA数据
- 维护数据质量

### 用户反馈
- 收集用户使用反馈
- 改进功能需求
- 优化用户体验

## 故障排除

### 常见问题
1. **包安装失败**
   - 检查R版本兼容性
   - 更新BiocManager
   - 检查网络连接

2. **Shiny应用部署失败**
   - 检查依赖包是否完整
   - 验证ShinyApps.io配置
   - 查看错误日志

3. **GitHub Pages不更新**
   - 检查Jekyll配置
   - 验证文件路径
   - 查看构建日志

## 联系和支持
- 项目GitHub: https://github.com/your-username/neta
- 邮箱: your-email@example.com
- 文档: https://your-username.github.io/neta/
