import requests
import json
from pprint import pprint

def get_token():

    url = 'https://jumpserver.tk/api/users/v1/token/'

    query_args = {
        "username": "admin",
        "password": "admin"
    }

    response = requests.post(url, data=query_args)

    return json.loads(response.text)['Token']

def get_user_info():

    url = 'https://jumpserver.tk/api/users/v1/users/'

    token = get_token()

    header_info = { "Authorization": 'Bearer ' + token }

    response = requests.get(url, headers=header_info)

    pprint(json.loads(response.text))

get_user_info()
