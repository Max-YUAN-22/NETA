#!/bin/bash
# NETA项目快速启动脚本

echo "🧬 NETA: Neuroendocrine Tumor Atlas 项目设置"
echo "=============================================="

# 检查R是否安装
if ! command -v R &> /dev/null; then
    echo "❌ 错误: R未安装。请先安装R (https://www.r-project.org/)"
    exit 1
fi

# 检查RStudio是否安装（可选）
if ! command -v rstudio &> /dev/null; then
    echo "⚠️  警告: RStudio未安装。建议安装RStudio以获得更好的开发体验"
fi

echo "✅ R环境检查完成"

# 创建必要的目录结构
echo "📁 创建项目目录结构..."
mkdir -p data/{raw,processed}
mkdir -p assets/{css,images,js}
mkdir -p shiny_app/{www,data}
mkdir -p R_scripts
mkdir -p docs
mkdir -p tests/test_data
mkdir -p scripts

echo "✅ 目录结构创建完成"

# 设置R环境
echo "🔧 设置R环境..."
cat > .Rprofile << 'EOF'
# NETA项目R配置文件
options(repos = c(CRAN = "https://cran.rstudio.com/"))

# 设置工作目录
if (file.exists("shiny_app")) {
  setwd("shiny_app")
}

# 加载常用包
if (require("shiny", quietly = TRUE)) {
  cat("Shiny已加载\n")
}
EOF

echo "✅ R环境配置完成"

# 创建Git仓库
if [ ! -d ".git" ]; then
    echo "📦 初始化Git仓库..."
    git init
    echo "✅ Git仓库初始化完成"
else
    echo "✅ Git仓库已存在"
fi

# 创建.gitignore文件
echo "📝 创建.gitignore文件..."
cat > .gitignore << 'EOF'
# R相关文件
.Rhistory
.RData
.Ruserdata
*.Rproj
*.Rproj.user/

# 数据文件
data/raw/*
data/processed/*
!data/raw/.gitkeep
!data/processed/.gitkeep

# 临时文件
*.tmp
*.temp
.DS_Store
Thumbs.db

# 日志文件
*.log

# 环境文件
.env
.Renviron

# 备份文件
*.bak
*.backup
EOF

echo "✅ .gitignore文件创建完成"

# 创建示例数据占位文件
echo "📊 创建示例数据文件..."
touch data/raw/.gitkeep
touch data/processed/.gitkeep

echo "✅ 示例数据文件创建完成"

# 安装R依赖包
echo "📦 安装R依赖包..."
Rscript R_scripts/install_dependencies.R

if [ $? -eq 0 ]; then
    echo "✅ R依赖包安装完成"
else
    echo "❌ R依赖包安装失败，请检查网络连接和R环境"
fi

# 创建快速启动脚本
echo "🚀 创建快速启动脚本..."
cat > start_neta.sh << 'EOF'
#!/bin/bash
echo "启动NETA Shiny应用..."
cd shiny_app
R -e "shiny::runApp(port=3838, host='0.0.0.0')"
EOF

chmod +x start_neta.sh

cat > start_website.sh << 'EOF'
#!/bin/bash
echo "启动Jekyll网站..."
if command -v bundle &> /dev/null; then
    bundle exec jekyll serve --host 0.0.0.0 --port 4000
else
    echo "请先安装Jekyll: gem install bundler jekyll"
fi
EOF

chmod +x start_website.sh

echo "✅ 启动脚本创建完成"

# 显示项目信息
echo ""
echo "🎉 NETA项目设置完成！"
echo ""
echo "📋 项目信息:"
echo "   - 项目名称: NETA (Neuroendocrine Tumor Atlas)"
echo "   - 项目类型: 神经内分泌肿瘤Bulk-RNA-seq数据库"
echo "   - 技术栈: R/Shiny + Jekyll + GitHub Pages"
echo ""
echo "🚀 快速开始:"
echo "   1. 启动Shiny应用: ./start_neta.sh"
echo "   2. 启动网站: ./start_website.sh"
echo "   3. 编辑配置: 修改_config.yml和index.md中的个人信息"
echo ""
echo "📚 文档:"
echo "   - 部署指南: DEPLOYMENT.md"
echo "   - 项目结构: PROJECT_STRUCTURE.md"
echo "   - 用户指南: docs/user_guide.md"
echo ""
echo "🔗 下一步:"
echo "   1. 修改_config.yml中的repository字段为您的GitHub用户名"
echo "   2. 更新index.md中的联系信息"
echo "   3. 准备神经内分泌肿瘤数据"
echo "   4. 部署到GitHub Pages和ShinyApps.io"
echo ""
echo "💡 提示: 运行 'Rscript R_scripts/data_processing.R' 开始数据处理"
echo ""
echo "Happy coding! 🧬✨"
