#!/usr/bin/env python3
"""
Font management utilities for After Effects rendering.
"""
import argparse
import os
import shutil
import sys
from pathlib import Path


def install_fonts(font_dir):
    """Install fonts from a directory to the system."""
    if not os.path.exists(font_dir):
        print(f"Font directory not found: {font_dir}")
        return False
    
    # Windows font directory
    system_fonts_dir = Path(os.environ.get('WINDIR', 'C:\\Windows')) / 'Fonts'
    
    font_extensions = ['.ttf', '.otf', '.woff', '.woff2']
    installed_count = 0
    
    for font_file in Path(font_dir).rglob('*'):
        if font_file.suffix.lower() in font_extensions:
            try:
                dest_path = system_fonts_dir / font_file.name
                if not dest_path.exists():
                    shutil.copy2(font_file, dest_path)
                    print(f"Installed font: {font_file.name}")
                    installed_count += 1
                else:
                    print(f"Font already exists: {font_file.name}")
            except Exception as e:
                print(f"Failed to install font {font_file.name}: {e}")
    
    print(f"Installed {installed_count} fonts")
    return True


def main():
    parser = argparse.ArgumentParser(description='Manage fonts for After Effects')
    parser.add_argument('--install', help='Install fonts from directory')
    parser.add_argument('--list', action='store_true', help='List installed fonts')
    
    args = parser.parse_args()
    
    if args.install:
        success = install_fonts(args.install)
        return 0 if success else 1
    elif args.list:
        system_fonts_dir = Path(os.environ.get('WINDIR', 'C:\\Windows')) / 'Fonts'
        fonts = list(system_fonts_dir.glob('*'))
        print(f"Found {len(fonts)} fonts in system directory")
        for font in sorted(fonts)[:10]:  # Show first 10
            print(f"  {font.name}")
        if len(fonts) > 10:
            print(f"  ... and {len(fonts) - 10} more")
        return 0
    else:
        parser.print_help()
        return 1


if __name__ == '__main__':
    sys.exit(main())