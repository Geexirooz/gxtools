#!/usr/bin/python

import sys
from urllib.parse import urlparse

url_dict = {}

for line in sys.stdin:
    org_url, path = line.split(" : ")

    org_url = org_url.strip()
    if org_url.endswith("/"):
        org_url = org_url[:-1]

    path = path.strip().strip('"')

    parsed_url = urlparse(org_url)
    base_url = parsed_url.scheme + "://" + parsed_url.netloc

    if path.startswith("/"):
        # Path starts with a slash, append it to the base URL
        full_url = base_url + path
    else:
        # Path does not start with a slash, treat it as a complete URL
        full_url = org_url + path

    print(full_url)
