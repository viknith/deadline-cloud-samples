#!/usr/bin/env python3
"""
Get user fonts from the project directory and install them.
"""
import argparse
import os
import sys
from pathlib import Path
from font_manager import install_fonts


def find_font_directories(project_dir):
    """Find font directories in the project structure."""
    font_dirs = []
    project_path = Path(project_dir)
    
    # Common font directory names
    font_dir_names = ['fonts', 'Fonts', 'FONTS', 'typefaces', 'Typefaces']
    
    for font_dir_name in font_dir_names:
        font_dir = project_path / font_dir_name
        if font_dir.exists() and font_dir.is_dir():
            font_dirs.append(font_dir)
    
    # Also check parent directories
    parent = project_path.parent
    for font_dir_name in font_dir_names:
        font_dir = parent / font_dir_name
        if font_dir.exists() and font_dir.is_dir():
            font_dirs.append(font_dir)
    
    return font_dirs


def main():
    parser = argparse.ArgumentParser(description='Install user fonts for After Effects project')
    parser.add_argument('project_file', help='After Effects project file path')
    
    args = parser.parse_args()
    
    project_dir = Path(args.project_file).parent
    print(f"Looking for fonts in project directory: {project_dir}")
    
    font_dirs = find_font_directories(project_dir)
    
    if not font_dirs:
        print("No font directories found")
        return 0
    
    total_installed = 0
    for font_dir in font_dirs:
        print(f"Installing fonts from: {font_dir}")
        if install_fonts(str(font_dir)):
            total_installed += 1
    
    print(f"Processed {len(font_dirs)} font directories")
    return 0


if __name__ == '__main__':
    sys.exit(main())