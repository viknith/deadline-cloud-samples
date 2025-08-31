#!/usr/bin/env python3
"""
Call aerender.exe with proper frame chunking for Docker containers.
"""
import argparse
import os
import subprocess
import sys
from pathlib import Path


def parse_frame_range(frame_range_str):
    """Parse frame range string like '1-100' into start and end integers."""
    if '-' in frame_range_str:
        start, end = frame_range_str.split('-', 1)
        return int(start), int(end)
    else:
        frame = int(frame_range_str)
        return frame, frame


def calculate_chunk_frames(start_frame, end_frame, chunk_size, chunk_index):
    """Calculate the actual frame range for this chunk."""
    chunk_start = start_frame + (chunk_index * chunk_size)
    chunk_end = min(chunk_start + chunk_size - 1, end_frame)
    
    if chunk_start > end_frame:
        return None, None
    
    return chunk_start, chunk_end


def main():
    parser = argparse.ArgumentParser(description='Render After Effects project with aerender')
    parser.add_argument('project_file', help='After Effects project file path')
    parser.add_argument('render_queue_index', type=int, help='Render queue item index')
    parser.add_argument('output_file', help='Output file pattern')
    parser.add_argument('frame_range', help='Frame range (e.g., "1-100")')
    parser.add_argument('--chunk-size', type=int, default=10, help='Frames per chunk')
    parser.add_argument('--index', type=int, default=0, help='Chunk index')
    parser.add_argument('--multi-frame-rendering', choices=['ON', 'OFF'], default='OFF')
    parser.add_argument('--max-cpu-usage-percentage', type=int, default=90)
    
    args = parser.parse_args()
    
    # Get aerender executable path
    aerender_exe = os.environ.get('AERENDER_EXECUTABLE', 
                                  r'C:\Program Files\Adobe\Adobe After Effects 2025\Support Files\aerender.exe')
    
    if not os.path.exists(aerender_exe):
        print(f"ERROR: aerender.exe not found at {aerender_exe}")
        return 1
    
    # Parse frame range
    start_frame, end_frame = parse_frame_range(args.frame_range)
    
    # Calculate chunk frames
    chunk_start, chunk_end = calculate_chunk_frames(start_frame, end_frame, 
                                                   args.chunk_size, args.index)
    
    if chunk_start is None:
        print(f"No frames to render for chunk {args.index}")
        return 0
    
    print(f"Rendering frames {chunk_start}-{chunk_end} from project {args.project_file}")
    
    # Build aerender command
    cmd = [
        aerender_exe,
        '-project', args.project_file,
        '-comp', str(args.render_queue_index),
        '-output', args.output_file,
        '-s', str(chunk_start),
        '-e', str(chunk_end),
        '-mfr', args.multi_frame_rendering,
        '-cpu_usage', str(args.max_cpu_usage_percentage)
    ]
    
    print(f"Executing: {' '.join(cmd)}")
    
    # Run aerender
    try:
        result = subprocess.run(cmd, check=True, capture_output=True, text=True)
        print("STDOUT:", result.stdout)
        if result.stderr:
            print("STDERR:", result.stderr)
        return 0
    except subprocess.CalledProcessError as e:
        print(f"ERROR: aerender failed with exit code {e.returncode}")
        print("STDOUT:", e.stdout)
        print("STDERR:", e.stderr)
        return e.returncode


if __name__ == '__main__':
    sys.exit(main())