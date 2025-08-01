FROM debian:bullseye AS builder

# 安装依赖
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    libglu1-mesa

# 创建非root用户
RUN useradd -ms /bin/bash flutter
USER flutter
WORKDIR /home/flutter

# 设置Flutter环境 - 使用3.29.3版本
RUN mkdir -p /home/flutter/sdk
WORKDIR /home/flutter/sdk
RUN curl -LO https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.29.3-stable.tar.xz && \
    tar xf flutter_linux_3.29.3-stable.tar.xz && \
    rm flutter_linux_3.29.3-stable.tar.xz
ENV PATH $PATH:/home/flutter/sdk/flutter/bin

# 配置Flutter
RUN git config --global --add safe.directory /home/flutter/sdk/flutter && \
    flutter config --no-analytics && \
    flutter config --enable-web && \
    flutter doctor -v

# 复制项目文件
WORKDIR /home/flutter/app
COPY --chown=flutter:flutter . .

# 获取依赖并生成JSON序列化代码
RUN flutter clean && \
    flutter pub get && \
    flutter pub run build_runner build --delete-conflicting-outputs

# 构建Web应用
RUN flutter build web --release

# 添加时间戳避免缓存 - 使用构建时间
RUN BUILD_TIME=$(date +%s) && \
    sed -i "s/var serviceWorkerVersion = \"{{flutter_service_worker_version}}\"/var serviceWorkerVersion = \"${BUILD_TIME}\"/g" build/web/index.html

# 使用nginx镜像部署
FROM nginx:stable-alpine

# 复制Flutter Web构建产物
COPY --from=builder /home/flutter/app/build/web /usr/share/nginx/html

# 确保favicon.ico存在
COPY --from=builder /home/flutter/app/assets/logo/favicon.ico /usr/share/nginx/html/favicon.ico
RUN chmod 644 /usr/share/nginx/html/favicon.ico

# 设置适当的权限
RUN chmod -R 755 /usr/share/nginx/html && \
    find /usr/share/nginx/html -type f -exec chmod 644 {} \;

EXPOSE 80 443
CMD ["nginx", "-g", "daemon off;"] 