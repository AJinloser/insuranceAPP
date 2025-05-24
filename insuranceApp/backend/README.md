# Insurance App 后端

保险应用后端服务，使用FastAPI构建的RESTful API。

## 技术栈

- 后端框架：FastAPI
- 数据库：PostgreSQL
- ORM：SQLAlchemy
- 部署：Docker
- 包管理工具：uv

## 快速开始

### 使用Docker部署（推荐）

1. 克隆仓库

```bash
git clone https://github.com/yourusername/insuranceAPP.git
cd insuranceAPP/backend
```

2. 配置环境变量

```bash
cp .env.example .env
```

编辑.env文件，根据需要修改配置。

3. 启动服务

```bash
docker-compose up -d
```

服务将在 http://localhost:8000 运行，API文档在 http://localhost:8000/api/docs 可访问。

### 本地开发

1. 安装依赖

```bash
pip install -r requirements.txt
```

2. 配置环境变量

```bash
cp .env.example .env
```

编辑.env文件，设置DATABASE_URL指向本地PostgreSQL数据库。

3. 运行开发服务器

```bash
uvicorn app.main:app --reload
```

## 项目结构

```
backend/
├── app/               # 应用代码
│   ├── api/           # API路由
│   ├── core/          # 核心配置
│   ├── db/            # 数据库相关
│   │   ├── crud/      # 数据库操作
│   ├── models/        # 数据模型
│   └── schemas/       # 数据架构
├── sql/               # SQL文件
├── tests/             # 测试
├── Dockerfile         # Docker配置
├── docker-compose.yml # Docker Compose配置
├── pyproject.toml     # Python项目配置
└── requirements.txt   # 依赖
```

## API文档

启动服务后，可以访问以下URL查看API文档：

- Swagger UI: http://localhost:8000/api/docs
- ReDoc: http://localhost:8000/api/redoc

## 数据库迁移

本项目使用自动导入SQL文件的方式进行数据库初始化，在应用启动时会自动导入`sql/`目录下的所有SQL文件。

要更新数据库架构，只需将新的SQL文件放入`sql/`目录，然后重启应用即可。

## 自定义配置

所有配置项都在`.env`文件中，包括：

- 数据库连接配置
- JWT密钥和过期时间
- AI模块API密钥列表

## Docker部署

项目包含Dockerfile和docker-compose.yml配置，可以轻松部署到任何支持Docker的环境。

```bash
# 构建镜像
docker-compose build

# 启动服务
docker-compose up -d

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down
```

## 开发指南

### 添加新的API端点

1. 在`app/api/`目录下创建新的路由文件
2. 在`app/main.py`中注册路由
3. 在`app/schemas/`中定义请求和响应模型
4. 在`app/models/`中定义数据模型（如需要）
5. 在`app/db/crud/`中实现数据库操作

### 添加新的保险产品类型

1. 在`sql/`目录下创建新的SQL文件
2. 在`app/models/insurance_product.py`的`PRODUCT_TYPE_MAPPING`中添加新的映射
3. 重启应用，新的产品类型将自动可用 