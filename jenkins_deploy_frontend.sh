# 部署脚本
# 客户端渲染前端通用

COMPONENT_NAME=renrenhua-h5
JENKINS_HTML_DIR=rrhh5/www                     #前端文件在jenkins workspace目录中的相对路径
NGINX_CONF_DIR=/etc/nginx/conf.d
NGINX_CONFIG_NAME=${COMPONENT_NAME}.conf
URI=rrhh5
NGINX_HTML_DIR=/data/html/$COMPONENT_NAME

if [ ! -d $NGINX_CONF_DIR ]; then
    mkdir -p $NGINX_CONF_DIR
fi

if [ ! -d $NGINX_HTML_DIR ]; then
    mkdir -p $NGINX_HTML_DIR
fi

cat > $NGINX_CONF_DIR/$NGINX_CONFIG_NAME << \EOF
server {
    listen 80;
    server_name _;

    access_log /var/log/nginx/COMPONENT_NAME_access.log main;
    error_log /var/log/nginx/COMPONENT_NAME_error.log;

    location /URI {
        alias /data/html/COMPONENT_NAME;
        index index.html;
    }
}
EOF

sed -i "s#COMPONENT_NAME#$COMPONENT_NAME#" $NGINX_CONF_DIR/$NGINX_CONFIG_NAME
sed -i "s#URI#$URI#" $NGINX_CONF_DIR/$NGINX_CONFIG_NAME
sed -i "s#NGINX_HTML_DIR#$NGINX_HTML_DIR#" $NGINX_CONF_DIR/$NGINX_CONFIG_NAME


rm -rf $NGINX_HTML_DIR/* && cp -r $JENKINS_HTML_DIR/* $NGINX_HTML_DIR/

nginx -s reload
