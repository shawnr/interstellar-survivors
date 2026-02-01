#!/usr/bin/env python3
"""
Generate shield assets for Interstellar Survivors.
Creates shield arc sprites for different coverage levels.
For Playdate: 1-bit graphics (black and white only).
"""

from PIL import Image, ImageDraw
import math
import os

# Asset dimensions
SHIELD_SIZE = 80  # Size of shield sprite (larger than station 64x64)
CENTER = SHIELD_SIZE // 2

# Shield coverage levels (fraction of circle)
SHIELD_LEVELS = {
    1: 0.5,    # 50% coverage (half circle)
    2: 0.667,  # 66.7% coverage
    3: 0.833,  # 83.3% coverage
    4: 1.0,    # 100% coverage (full circle)
}

# Shield radius (just outside the station)
SHIELD_RADIUS = 36
SHIELD_THICKNESS = 4

def draw_shield_arc(draw, center_x, center_y, radius, start_angle, end_angle, thickness, color):
    """Draw an arc segment using lines for 1-bit display."""
    # Draw multiple arcs at different radii for thickness
    for r in range(radius - thickness // 2, radius + thickness // 2 + 1):
        # Calculate arc points
        segments = 32
        angle_range = end_angle - start_angle
        for i in range(segments):
            a1 = start_angle + (i / segments) * angle_range
            a2 = start_angle + ((i + 1) / segments) * angle_range

            x1 = center_x + int(r * math.cos(math.radians(a1)))
            y1 = center_y + int(r * math.sin(math.radians(a1)))
            x2 = center_x + int(r * math.cos(math.radians(a2)))
            y2 = center_y + int(r * math.sin(math.radians(a2)))

            draw.line([(x1, y1), (x2, y2)], fill=color, width=1)

def generate_shield_sprite(level, coverage):
    """Generate a shield sprite for given level."""
    # Create white background (transparent in Playdate)
    img = Image.new('1', (SHIELD_SIZE, SHIELD_SIZE), 1)  # 1 = white
    draw = ImageDraw.Draw(img)

    # Calculate arc angles (shield faces down/opposite of slot 0 which faces up)
    # 0 degrees = right, 90 = down, 180 = left, 270 = up
    half_angle = (coverage * 360) / 2

    # Center the arc at bottom (90 degrees)
    start_angle = 90 - half_angle
    end_angle = 90 + half_angle

    # Draw the shield arc (black = 0)
    draw_shield_arc(draw, CENTER, CENTER, SHIELD_RADIUS, start_angle, end_angle, SHIELD_THICKNESS, 0)

    # Add decorative end caps
    if coverage < 1.0:
        # Draw small circles at arc ends
        for angle in [start_angle, end_angle]:
            x = CENTER + int(SHIELD_RADIUS * math.cos(math.radians(angle)))
            y = CENTER + int(SHIELD_RADIUS * math.sin(math.radians(angle)))
            draw.ellipse([x-2, y-2, x+2, y+2], fill=0)

    return img

def generate_shield_hit_effect():
    """Generate a shield hit flash effect."""
    img = Image.new('1', (SHIELD_SIZE, SHIELD_SIZE), 1)  # White background
    draw = ImageDraw.Draw(img)

    # Draw concentric dashed arcs for hit effect
    for r in range(SHIELD_RADIUS - 4, SHIELD_RADIUS + 6, 2):
        segments = 16
        for i in range(segments):
            if i % 2 == 0:  # Dashed pattern
                a1 = (i / segments) * 360
                a2 = ((i + 1) / segments) * 360
                x1 = CENTER + int(r * math.cos(math.radians(a1)))
                y1 = CENTER + int(r * math.sin(math.radians(a1)))
                x2 = CENTER + int(r * math.cos(math.radians(a2)))
                y2 = CENTER + int(r * math.sin(math.radians(a2)))
                draw.line([(x1, y1), (x2, y2)], fill=0, width=2)

    return img

def generate_shield_recharge_indicator():
    """Generate a shield recharge indicator (circular progress)."""
    img = Image.new('1', (16, 16), 1)  # Small indicator
    draw = ImageDraw.Draw(img)

    # Simple circular outline
    draw.ellipse([1, 1, 14, 14], outline=0, width=2)

    # Quarter segment to show progress direction
    for i in range(8):
        a = i * 45
        x = 8 + int(5 * math.cos(math.radians(a)))
        y = 8 + int(5 * math.sin(math.radians(a)))
        if i < 2:  # First quarter
            draw.point((x, y), fill=0)

    return img

def main():
    output_dir = os.path.dirname(os.path.abspath(__file__))
    shared_dir = os.path.join(output_dir, 'shared')

    # Ensure output directory exists
    os.makedirs(shared_dir, exist_ok=True)

    print("Generating shield assets...")

    # Generate shield sprites for each level
    for level, coverage in SHIELD_LEVELS.items():
        img = generate_shield_sprite(level, coverage)
        filename = os.path.join(shared_dir, f'shield_level_{level}.png')
        img.save(filename)
        print(f"  Created: shield_level_{level}.png (coverage: {coverage*100:.0f}%)")

    # Generate shield hit effect
    hit_img = generate_shield_hit_effect()
    hit_filename = os.path.join(shared_dir, 'shield_hit_effect.png')
    hit_img.save(hit_filename)
    print(f"  Created: shield_hit_effect.png")

    # Generate recharge indicator
    recharge_img = generate_shield_recharge_indicator()
    recharge_filename = os.path.join(shared_dir, 'shield_recharge.png')
    recharge_img.save(recharge_filename)
    print(f"  Created: shield_recharge.png")

    print("\nShield assets generated successfully!")
    print(f"Output directory: {shared_dir}")

if __name__ == '__main__':
    main()
