#!/bin/bash

# 创建自签名SSL证书
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout thu-skysail.com.key -out thu-skysail.com.pem \
  -subj "/CN=thu-skysail.com/O=InsuranceApp/C=CN" \
  -addext "subjectAltName=DNS:thu-skysail.com,DNS:www.thu-skysail.com"

# 设置适当的权限
chmod 600 thu-skysail.com.key
chmod 644 thu-skysail.com.pem

echo "自签名SSL证书已生成:"
echo "- 证书文件: thu-skysail.com.pem"
echo "- 私钥文件: thu-skysail.com.key" 