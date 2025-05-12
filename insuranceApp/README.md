# 保险应用项目

这是一个基于Flutter和FastAPI的保险应用项目，提供跨平台支持（iOS、Android和Web）。

## 项目结构

```
insuranceApp/
├── backend/         # FastAPI后端服务
│   ├── app/         # 应用代码
│   │   ├── api/     # API路由
│   │   ├── core/    # 核心配置
│   │   ├── db/      # 数据库
│   │   ├── models/  # 数据模型
│   │   └── schemas/ # 数据架构
│   ├── tests/       # 测试
│   ├── Dockerfile   # Docker配置
│   ├── pyproject.toml # Python项目配置
│   └── requirements.txt # 依赖
└── frontend/        # Flutter前端
    ├── lib/         # 应用代码
    │   ├── models/  # 数据模型
    │   ├── screens/ # 屏幕页面
    │   ├── services/# 服务
    │   ├── utils/   # 工具类
    │   └── widgets/ # UI组件
    ├── assets/      # 资源文件
    └── pubspec.yaml # Flutter项目配置
```

## 功能

目前实现的功能：

- 用户认证系统
  - 登录
  - 注册
  - 重置密码

## 技术栈

- **前端**：Flutter (三端互通：iOS、Android、Web)
- **后端**：Python FastAPI
- **数据库**：PostgreSQL
- **部署**：Docker
- **包管理工具**：uv

## 开始使用

### 后端服务

1. 创建并配置环境变量文件:
   ```
   cp backend/.env.example backend/.env
   # 编辑 .env 文件设置参数
   ```

2. 使用Docker启动后端服务:
   ```
   cd backend
   docker-compose up --build
   ```

### 前端应用

1. 创建并配置环境变量文件:
   ```
   cp frontend/.env.example frontend/.env
   # 编辑 .env 文件设置API基础URL
   ```

2. 安装依赖并启动Flutter应用:
   ```
   cd frontend
   flutter pub get
   flutter pub run build_runner build --delete-conflicting-outputs  # 生成JSON序列化代码
   flutter run
   ```

## API文档

启动后端服务后，可以访问以下URL查看API文档：
- Swagger UI: http://localhost:8000/api/docs
- ReDoc: http://localhost:8000/api/redoc

## 开发人员

- 保险应用团队 