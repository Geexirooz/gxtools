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
        url_key = parsed_url.netloc + path #full_url without scheme
        url_scheme = parsed_url.scheme
    else:
        # Path does not start with a slash, treat it as a complete URL
        full_url = org_url + path
        url_key = parsed_url.netloc + parsed_url.path + path #full_url without scheme
        url_scheme = parsed_url.scheme

    if url_key not in url_dict:
        url_dict[url_key] = url_scheme
    else:
        # If 'http' is found but 'https' is already present, ignore 'http'
        if url_dict[url_key] == 'https':
            continue
        # Otherwise, keep the first encounter (which is either http or https)
        elif url_dict[url_key] == 'http' and url_scheme == 'https':
            url_dict[url_key] = 'https'
        else:
            continue

# Output the result
for url, scheme in url_dict.items():
    print(scheme + "://" + url)
