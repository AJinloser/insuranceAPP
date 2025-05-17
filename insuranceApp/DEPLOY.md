# 部署指南

本文档介绍如何将 Insurance App 部署到服务器，并通过 thu-skysail.com 域名访问。

## 前提条件

1. 已有服务器，并已安装 Docker 和 Docker Compose
2. 已有域名 thu-skysail.com，并已将其 DNS 解析到服务器 IP
3. 服务器开放了 80 和 443 端口

## 部署步骤

### 1. 准备部署环境

```bash
# 克隆代码库到服务器
git clone <项目仓库地址> /path/to/insuranceApp
cd /path/to/insuranceApp

# 创建必要的目录
mkdir -p insuranceApp/nginx/ssl
```

### 2. 生成 SSL 证书

如果您已有正式的 SSL 证书，请将证书文件和私钥文件分别命名为 `thu-skysail.com.pem` 和 `thu-skysail.com.key`，并放置在 `insuranceApp/nginx/ssl` 目录中。

如果您还没有证书，可以使用提供的脚本生成自签名证书（仅用于测试）：

```bash
cd insuranceApp/nginx/ssl
chmod +x generate-cert.sh
./generate-cert.sh
```

### 3. 构建并启动服务

```bash
cd insuranceApp
docker-compose up -d
```

这将启动以下服务：
- 前端服务：Flutter Web 应用，使用 Nginx 提供服务
- 后端服务：FastAPI 应用
- 数据库服务：PostgreSQL

### 4. 验证部署

打开浏览器，访问 https://thu-skysail.com，应该能看到 Insurance App 的界面。

如果使用自签名证书，浏览器可能会显示安全警告，这是正常的，您可以选择继续访问。

### 5. 查看日志

如果遇到问题，可以查看容器日志：

```bash
# 查看前端日志
docker-compose logs frontend

# 查看后端日志
docker-compose logs backend

# 查看数据库日志
docker-compose logs db
```

### 6. 更新应用

如果需要更新应用，可以执行：

```bash
# 拉取最新代码
git pull

# 重新构建并启动服务
docker-compose down
docker-compose up -d --build
```

## 常见问题

1. **无法访问网站**
   - 检查域名是否正确解析到服务器 IP
   - 检查服务器防火墙是否允许 80 和 443 端口
   - 查看 Nginx 日志：`docker-compose logs frontend`

2. **网站显示默认 Nginx 欢迎页面**
   - 可能是 Flutter Web 应用构建失败，检查前端日志
   - 检查 Nginx 配置文件是否正确

3. **后端 API 无法访问**
   - 检查后端服务是否正常运行
   - 查看后端日志：`docker-compose logs backend` 