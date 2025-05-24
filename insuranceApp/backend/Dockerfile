FROM python:3.11-slim

WORKDIR /app

# 复制项目文件
COPY requirements.txt .
COPY pyproject.toml .

# 安装依赖
RUN pip install --no-cache-dir -U uv
RUN uv pip install --system --no-cache-dir -r requirements.txt

# 复制应用代码
COPY ./app ./app
# 复制SQL文件
COPY ./sql ./sql

# 设置运行命令
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"] 