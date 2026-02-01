#!/usr/bin/env python3
"""
Generate menu background pattern for Interstellar Survivors.
Creates a repeating chevron/zigzag pattern similar to the user's reference.
For Playdate: 1-bit graphics (black and white only).
"""

from PIL import Image, ImageDraw
import os

# Pattern dimensions - should tile seamlessly
PATTERN_WIDTH = 400   # Full screen width
PATTERN_HEIGHT = 240  # Full screen height

# Chevron parameters
CHEVRON_WIDTH = 16    # Width of each chevron unit
CHEVRON_HEIGHT = 8    # Height of each chevron unit
LINE_THICKNESS = 1    # Thickness of the lines

def draw_chevron_pattern(draw, width, height):
    """Draw a repeating chevron/zigzag pattern."""

    # Draw horizontal rows of chevrons
    for row in range(0, height + CHEVRON_HEIGHT, CHEVRON_HEIGHT):
        # Offset every other row for the interlocking pattern
        offset = (row // CHEVRON_HEIGHT) % 2 * (CHEVRON_WIDTH // 2)

        for col in range(-CHEVRON_WIDTH, width + CHEVRON_WIDTH, CHEVRON_WIDTH):
            x = col + offset
            y = row

            # Draw a single chevron (inverted V shape)
            # Left side of chevron
            x1, y1 = x, y + CHEVRON_HEIGHT // 2
            x2, y2 = x + CHEVRON_WIDTH // 2, y
            draw.line([(x1, y1), (x2, y2)], fill=0, width=LINE_THICKNESS)

            # Right side of chevron
            x3, y3 = x + CHEVRON_WIDTH // 2, y
            x4, y4 = x + CHEVRON_WIDTH, y + CHEVRON_HEIGHT // 2
            draw.line([(x3, y3), (x4, y4)], fill=0, width=LINE_THICKNESS)

            # Bottom connections
            x5, y5 = x, y + CHEVRON_HEIGHT // 2
            x6, y6 = x + CHEVRON_WIDTH // 2, y + CHEVRON_HEIGHT
            draw.line([(x5, y5), (x6, y6)], fill=0, width=LINE_THICKNESS)

            x7, y7 = x + CHEVRON_WIDTH // 2, y + CHEVRON_HEIGHT
            x8, y8 = x + CHEVRON_WIDTH, y + CHEVRON_HEIGHT // 2
            draw.line([(x7, y7), (x8, y8)], fill=0, width=LINE_THICKNESS)

def generate_menu_pattern():
    """Generate the menu background pattern."""
    # Create white background
    img = Image.new('1', (PATTERN_WIDTH, PATTERN_HEIGHT), 1)  # 1 = white
    draw = ImageDraw.Draw(img)

    # Draw the chevron pattern
    draw_chevron_pattern(draw, PATTERN_WIDTH, PATTERN_HEIGHT)

    return img

def main():
    output_dir = os.path.dirname(os.path.abspath(__file__))
    ui_dir = os.path.join(output_dir, 'ui')

    # Ensure output directory exists
    os.makedirs(ui_dir, exist_ok=True)

    print("Generating menu background pattern...")

    # Generate full-size pattern
    pattern_img = generate_menu_pattern()
    pattern_filename = os.path.join(ui_dir, 'menu_pattern_bg.png')
    pattern_img.save(pattern_filename)
    print(f"  Created: menu_pattern_bg.png ({PATTERN_WIDTH}x{PATTERN_HEIGHT})")

    print("\nMenu pattern generated successfully!")
    print(f"Output directory: {ui_dir}")

if __name__ == '__main__':
    main()
