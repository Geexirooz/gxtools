#!/usr/bin/python

import sys
from urllib.parse import urlparse

url_dict = {}

for url in sys.stdin:
    url = url.strip().strip('/')
    parsed_url = urlparse(url)
    url_scheme = parsed_url.scheme
    url_no_scheme = url[len(url_scheme) + 3:] # +3 for ://

    if url_no_scheme not in url_dict:
        url_dict[url_no_scheme] = url_scheme
    else:
        # If 'http' is found but 'https' is already present, ignore 'http'
        if url_dict[url_no_scheme] == 'https':
            continue
        # If 'https' is found, but 'http' is already present, replace 'https'
        elif url_dict[url_no_scheme] == 'http' and url_scheme == 'https':
            url_dict[url_no_scheme] = 'https'
        # What??? leave it
        else:
            continue

# Output the result
for url, scheme in url_dict.items():
    print(scheme + "://" + url)
