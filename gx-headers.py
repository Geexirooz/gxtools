#!/usr/bin/python

import argparse
import re

def read_headers(file_path):
    headers = []
    with open(file_path, 'r') as file:
        for line in file:
            # Remove newline and extra spaces from each header line
            if not re.match(r'^\s*$', line):
                headers.append(line.strip())
    return headers

def print_multiple_headers(headers, switch, style):
    if style == 'unix':
        switch = f'-{switch}'  # Single hyphen switch
    elif style == 'linux':
        switch = f'--{switch}'  # Double hyphen switch
    for header in headers:
        print(f'{switch} \'{header}\'', end=' ')

def print_single_header(headers):
    print("\\n".join(headers))

def main():
    # Set up the argument parser
    parser = argparse.ArgumentParser(description="Process and format HTTP headers.")
    parser.add_argument('headers_file', help="Path to the headers.txt file")
    parser.add_argument('--format', choices=['single', 'multiple'], default='multiple', help="Choose the output format ('single' or 'multiple')")
    parser.add_argument('--switch', default='header', help="Specify the header switch name (e.g., 'header', 'h')")
    parser.add_argument('--style', choices=['unix', 'linux'], default='linux', help="Specify the style of the switch -> unix(single) or linux(double) hyphen")
 
    args = parser.parse_args()

    # Read headers from file
    headers = read_headers(args.headers_file)

    # Print headers in the chosen format
    if args.format == 'multiple':
        print_multiple_headers(headers, args.switch, args.style)
    else:
        print_single_header(headers)

if __name__ == "__main__":
    main()

