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
mkdir -p nginx/ssl
```

### 2. 生成 SSL 证书

如果您已有正式的 SSL 证书，请将证书文件和私钥文件分别命名为 `thu-skysail.com.pem` 和 `thu-skysail.com.key`，并放置在 `nginx/ssl` 目录中。

如果您还没有证书，可以使用提供的脚本生成自签名证书（仅用于测试）：

```bash
cd nginx/ssl
chmod +x generate-cert.sh
./generate-cert.sh
```

### 3. 构建并启动服务

```bash
# 构建并启动所有服务
docker-compose up -d --build

# 查看服务状态
docker-compose ps
```

### 4. 验证部署

打开浏览器，访问 https://thu-skysail.com，应该能看到 Insurance App 的界面。

如果使用自签名证书，浏览器可能会显示安全警告，这是正常的，您可以选择继续访问。

## 更新应用

当需要更新应用时：

```bash
# 拉取最新代码
git pull

# 重新构建并启动服务（这会自动处理缓存问题）
docker-compose down
docker-compose up -d --build
```

## 缓存解决方案

### 问题说明

部署更新后，用户可能仍然看到旧版本的应用，这是由于浏览器缓存造成的。本项目已配置了缓存解决方案：

### 1. Nginx缓存策略

- **主应用文件**（index.html）：强制不缓存
- **Service Worker**：强制不缓存
- **主要JS文件**：短期缓存（5分钟）
- **静态资源**：适度缓存（1小时）
- **图片资源**：长期缓存（1天）

### 2. 构建时缓存破坏

- 每次构建时自动生成新的时间戳
- Service Worker版本自动更新
- 确保浏览器获取最新版本

### 3. 用户端解决方案

如果用户仍然看到旧版本，可以：

1. **强制刷新**：Ctrl+F5 (Windows) 或 Cmd+Shift+R (Mac)
2. **清除缓存**：在浏览器设置中清除缓存
3. **隐私模式**：使用浏览器的隐私/无痕模式访问

## 查看日志

如果遇到问题，可以查看容器日志：

```bash
# 查看前端日志
docker-compose logs frontend

# 查看后端日志
docker-compose logs backend

# 查看数据库日志
docker-compose logs db

# 查看所有服务日志
docker-compose logs
```

## 常见问题

1. **无法访问网站**
   - 检查域名是否正确解析到服务器 IP
   - 检查防火墙是否开放80和443端口
   - 检查SSL证书是否正确配置

2. **用户看到旧版本**
   - 确认执行了 `docker-compose up -d --build`
   - 指导用户强制刷新浏览器
   - 检查nginx配置是否正确

3. **构建失败**
   - 检查Docker和Docker Compose版本
   - 查看构建日志确定具体错误
   - 确保有足够的磁盘空间

4. **服务启动失败**
   - 检查端口是否被占用
   - 查看容器日志
   - 检查配置文件是否正确

## 维护建议

1. **定期清理**：定期清理Docker镜像和容器
   ```bash
   docker system prune -f
   ```

2. **监控资源**：监控服务器CPU、内存和磁盘使用情况
   ```bash
   docker stats
   ```

3. **备份数据**：定期备份数据库
   ```bash
   docker-compose exec db pg_dump -U postgres insurance_app > backup.sql
   ``` 