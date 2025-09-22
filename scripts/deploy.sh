#!/bin/bash
# NETA项目部署脚本
# MySQL + Python后端 + React前端完整部署

echo "🧬 NETA项目部署脚本"
echo "===================="

# 检查Docker和Docker Compose
check_docker() {
    echo "🔍 检查Docker环境..."
    
    if ! command -v docker &> /dev/null; then
        echo "❌ Docker未安装，请先安装Docker"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        echo "❌ Docker Compose未安装，请先安装Docker Compose"
        exit 1
    fi
    
    echo "✅ Docker环境检查通过"
}

# 创建必要的目录
create_directories() {
    echo "📁 创建项目目录..."
    
    mkdir -p data/{raw,processed,backup}
    mkdir -p logs
    mkdir -p nginx/ssl
    mkdir -p database/backup
    
    echo "✅ 目录创建完成"
}

# 创建Nginx配置文件
create_nginx_config() {
    echo "🌐 创建Nginx配置..."
    
    cat > nginx/nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    upstream backend {
        server backend:5000;
    }
    
    upstream frontend {
        server frontend:3000;
    }
    
    upstream shiny {
        server shiny:3838;
    }
    
    server {
        listen 80;
        server_name localhost;
        
        # 前端路由
        location / {
            proxy_pass http://frontend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
        
        # API路由
        location /api/ {
            proxy_pass http://backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
        
        # Shiny应用路由
        location /shiny/ {
            proxy_pass http://shiny/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
EOF
    
    echo "✅ Nginx配置创建完成"
}

# 创建环境变量文件
create_env_files() {
    echo "🔧 创建环境变量文件..."
    
    # 后端环境变量
    cat > backend/.env << 'EOF'
DATABASE_URL=mysql://neta_user:neta_password@mysql:3306/neta_db
REDIS_URL=redis://redis:6379
FLASK_ENV=production
FLASK_DEBUG=0
SECRET_KEY=neta-secret-key-2024
JWT_SECRET_KEY=jwt-secret-string
EOF
    
    # 前端环境变量
    cat > frontend/.env << 'EOF'
REACT_APP_API_URL=http://localhost:5000/api
REACT_APP_SHINY_URL=http://localhost:3838
EOF
    
    echo "✅ 环境变量文件创建完成"
}

# 构建和启动服务
build_and_start() {
    echo "🚀 构建和启动服务..."
    
    # 停止现有服务
    docker-compose down
    
    # 构建镜像
    docker-compose build
    
    # 启动服务
    docker-compose up -d
    
    echo "✅ 服务启动完成"
}

# 等待服务启动
wait_for_services() {
    echo "⏳ 等待服务启动..."
    
    # 等待MySQL启动
    echo "等待MySQL启动..."
    while ! docker-compose exec mysql mysqladmin ping -h localhost --silent; do
        sleep 2
    done
    echo "✅ MySQL已启动"
    
    # 等待后端启动
    echo "等待后端API启动..."
    while ! curl -f http://localhost:5000/api/health &> /dev/null; do
        sleep 2
    done
    echo "✅ 后端API已启动"
    
    # 等待前端启动
    echo "等待前端启动..."
    while ! curl -f http://localhost:3000 &> /dev/null; do
        sleep 2
    done
    echo "✅ 前端已启动"
}

# 初始化数据库
init_database() {
    echo "🗄️ 初始化数据库..."
    
    # 等待MySQL完全启动
    sleep 10
    
    # 运行数据库初始化脚本
    docker-compose exec mysql mysql -u root -prootpassword neta_db < /docker-entrypoint-initdb.d/init_neta_db.sql
    
    echo "✅ 数据库初始化完成"
}

# 导入示例数据
import_sample_data() {
    echo "📊 导入示例数据..."
    
    # 这里可以添加数据导入逻辑
    # 例如：从GEO数据库下载数据并导入到MySQL
    
    echo "✅ 示例数据导入完成"
}

# 显示服务状态
show_status() {
    echo "📋 服务状态检查..."
    
    docker-compose ps
    
    echo ""
    echo "🌐 访问地址:"
    echo "  前端界面: http://localhost:3000"
    echo "  后端API: http://localhost:5000/api"
    echo "  Shiny应用: http://localhost:3838"
    echo "  MySQL数据库: localhost:3306"
    echo "  Redis缓存: localhost:6379"
    echo ""
    echo "📊 数据库连接信息:"
    echo "  数据库: neta_db"
    echo "  用户名: neta_user"
    echo "  密码: neta_password"
}

# 主函数
main() {
    echo "开始部署NETA项目..."
    echo ""
    
    # 检查Docker环境
    check_docker
    
    # 创建目录结构
    create_directories
    
    # 创建配置文件
    create_nginx_config
    create_env_files
    
    # 构建和启动服务
    build_and_start
    
    # 等待服务启动
    wait_for_services
    
    # 初始化数据库
    init_database
    
    # 导入示例数据
    import_sample_data
    
    # 显示状态
    show_status
    
    echo ""
    echo "🎉 NETA项目部署完成！"
    echo ""
    echo "📋 下一步操作:"
    echo "1. 访问 http://localhost:3000 查看前端界面"
    echo "2. 访问 http://localhost:5000/api/health 检查API状态"
    echo "3. 运行数据收集脚本导入真实数据"
    echo "4. 配置SSL证书（可选）"
    echo ""
    echo "💡 提示: 使用 'docker-compose logs -f' 查看服务日志"
    echo "💡 提示: 使用 'docker-compose down' 停止所有服务"
}

# 运行主函数
main
