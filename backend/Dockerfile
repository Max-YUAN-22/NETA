# 后端Python应用Dockerfile
FROM python:3.9-slim

# 设置工作目录
WORKDIR /app

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    mysql-client \
    r-base \
    r-base-dev \
    libmysqlclient-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# 安装Python依赖
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 安装R包
RUN Rscript -e "install.packages(c('GEOquery', 'dplyr', 'ggplot2', 'shiny', 'DT', 'plotly'), repos='https://cran.rstudio.com/')"

# 复制应用代码
COPY . .

# 创建必要的目录
RUN mkdir -p data logs

# 设置环境变量
ENV PYTHONPATH=/app
ENV FLASK_APP=app.py
ENV FLASK_ENV=production

# 暴露端口
EXPOSE 5000

# 健康检查
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:5000/api/health || exit 1

# 启动命令
CMD ["python", "app.py"]
