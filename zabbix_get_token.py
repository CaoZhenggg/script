#!/usr/bin/env python3
#Author: CaoZheng

import getpass
import urllib
import json

zabbix_server = '192.168.130.128'
zabbix_user = input("zabbix user: ")
zabbix_password = getpass.getpass("user password: ")

def get_token(username, password):
    zabbix_api_url = 'http://%s/zabbix/api_jsonrpc.php' % zabbix_server
    request_header = {'Content-Type': 'application/json-rpc'}
    request_content = {
        "jsonrpc": "2.0",
        "method": "user.login",
        "params": {
            "user": username,
            "password": password
            },
        "id": 1,
    }
    request_content_encode = json.dumps(request_content).encode('utf-8')
    request = urllib.request.Request(zabbix_api_url, data=request_content_encode, headers=request_header)

    try:
        request_result = urllib.request.urlopen(request)
    except Exception as e:
        print('Authentication failed: ', e)
    else:
        response = eval(request_result.read().decode('utf-8'))
        print(response['result'])

def main():
    get_token(zabbix_user, zabbix_password)

if __name__ == '__main__':
    main()
