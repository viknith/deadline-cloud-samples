#!/usr/bin/env python3
"""
Create output directory if it doesn't exist.
"""
import argparse
import os
import sys
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description='Create output directory')
    parser.add_argument('output_dir', help='Output directory path')
    
    args = parser.parse_args()
    
    try:
        output_path = Path(args.output_dir)
        output_path.mkdir(parents=True, exist_ok=True)
        print(f"Output directory created: {output_path}")
        return 0
    except Exception as e:
        print(f"ERROR: Failed to create output directory: {e}")
        return 1


if __name__ == '__main__':
    sys.exit(main())