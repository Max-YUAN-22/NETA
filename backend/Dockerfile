FROM python:3.9-slim

WORKDIR /app

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    r-base \
    r-base-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libmariadb-dev \
    && rm -rf /var/lib/apt/lists/*

# 安装Python依赖
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt gunicorn==21.2.0

# 安装R包
RUN R -e "install.packages(c('optparse', 'jsonlite', 'ggplot2', 'pheatmap'), repos='https://cran.r-project.org/')"

# 复制应用代码
COPY . .

# 创建数据目录
RUN mkdir -p data/processed/analysis_results

# 暴露端口
EXPOSE 5000

# 启动命令（生产使用 gunicorn）
ENV PORT=5000
CMD ["gunicorn", "-w", "2", "-b", "0.0.0.0:${PORT}", "app:app"]
