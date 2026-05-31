#!/bin/bash
# Convert draw.io file to PNG with high quality settings
# Usage: ./convert_to_png.sh <input.drawio> [output.png]

set -e

if [ $# -lt 1 ]; then
    echo "Usage: $0 <input.drawio> [output.png]"
    exit 1
fi

INPUT="$1"
# Default output: replace .drawio extension with .png
if [ -z "$2" ]; then
    OUTPUT="${INPUT%.drawio}.png"
else
    OUTPUT="$2"
fi

# Check if drawio CLI is installed
if ! command -v drawio &> /dev/null; then
    echo "Error: drawio CLI is not installed."
    echo "Install with: brew install --cask drawio"
    exit 1
fi

# Check if input file exists
if [ ! -f "$INPUT" ]; then
    echo "Error: Input file '$INPUT' does not exist."
    exit 1
fi

# Convert to PNG with high quality settings
# -x: export mode
# -f png: output format
# -s 2: 2x scale for high resolution
# -b white: white background for better arrow visibility
drawio -x -f png -s 2 -b white -o "$OUTPUT" "$INPUT" 2>/dev/null

echo "✅ Converted: $INPUT → $OUTPUT"
