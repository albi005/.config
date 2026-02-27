#!/usr/bin/env nix-shell
#!nix-shell -p python3 -i python3

import sys
import urllib.request
import re

def extract_categories(ics_content):
    categories = set()
    pattern = re.compile(r'^CATEGORIES:(.*)$', re.MULTILINE)
    for match in pattern.finditer(ics_content):
        category = match.group(1).strip()
        if category:
            categories.add(category)
    return categories

def main():
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <ics_url>", file=sys.stderr)
        sys.exit(1)
    
    url = sys.argv[1]
    
    try:
        with urllib.request.urlopen(url) as response:
            content = response.read().decode('utf-8')
    except Exception as e:
        print(f"Error fetching URL: {e}", file=sys.stderr)
        sys.exit(1)
    
    categories = extract_categories(content)
    
    for cat in sorted(categories):
        print(cat)

if __name__ == "__main__":
    main()
