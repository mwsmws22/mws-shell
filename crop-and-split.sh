#!/bin/bash

# README
# Uses ImageMagick to perform the following operatations on a directory of images:
# 1. Crops the left and right sides of each image by a specified number of pixels.
# 2. Splits each cropped image into two equal parts, doubling the number of files.
#
# Requirements:
# - ImageMagick: https://imagemagick.org/script/download.php
#   - Make sure to select "Install legacy utilities (e.g. convert)" during installation.
#
# Parameters:
# - $1: Directory path containing the images.
# - $2: Width in pixels to crop from both the left and right sides.
#
# Example Usage:
# ./crop-and-split.sh ~/pics 200
# This will crop 50 pixels from the left and right sides of each image and split them into two equal parts.

# Check if the required arguments are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <directory_path> <width_in_pixels>"
    exit 1
fi

# Assign arguments to variables
DIRECTORY=$1
CROP_WIDTH=$2

# Check if the directory exists
if [ ! -d "$DIRECTORY" ]; then
    echo "Error: Directory $DIRECTORY does not exist."
    exit 1
fi

# Initialize page numbering
PAGE_NUMBER=1

# Process each image in the directory
for IMAGE in $(ls "$DIRECTORY"/*.{jpg,jpeg,png} 2>/dev/null | sort -V); do
    # Skip if no matching files are found
    [ -e "$IMAGE" ] || continue

    # Get the image filename without extension
    BASENAME=$(basename "$IMAGE")
    FILENAME="${BASENAME%.*}"
    EXTENSION="${BASENAME##*.}"

    # Get the original width of the image
    ORIGINAL_WIDTH=$(identify -format "%w" "$IMAGE")

    # Calculate the new width after cropping both sides
    NEW_WIDTH=$((ORIGINAL_WIDTH - 2 * CROP_WIDTH))

    # Crop the left and right sides
    mogrify -crop "${NEW_WIDTH}x+${CROP_WIDTH}+0" "$IMAGE"

    # Get the width and height of the cropped image
    WIDTH=$(identify -format "%w" "$IMAGE")
    HEIGHT=$(identify -format "%h" "$IMAGE")

    # Calculate the width of each half based on the cropped width
    HALF_WIDTH=$((WIDTH / 2))

    # Generate filenames for the split images
    LEFT_PAGE="$DIRECTORY/${PAGE_NUMBER}.${EXTENSION}"
    PAGE_NUMBER=$((PAGE_NUMBER + 1))
    RIGHT_PAGE="$DIRECTORY/${PAGE_NUMBER}.${EXTENSION}"
    PAGE_NUMBER=$((PAGE_NUMBER + 1))

    # Check if the filenames already exist
    if [ -e "$LEFT_PAGE" ] || [ -e "$RIGHT_PAGE" ]; then
        echo "Error: File $LEFT_PAGE or $RIGHT_PAGE already exists."
        exit 1
    fi

    # Split the image into two equal parts
    magick "$IMAGE" -crop "${HALF_WIDTH}x${HEIGHT}+${HALF_WIDTH}+0" "$LEFT_PAGE"
    magick "$IMAGE" -crop "${HALF_WIDTH}x${HEIGHT}+0+0" "$RIGHT_PAGE"

    # Remove the original cropped image
    rm "$IMAGE"
done

echo "Processing complete. Images have been cropped and split."