#!/usr/bin/env python3
"""
Generate bonus item graphics for Interstellar Survivors.
Creates a new "Shield Capacitor" bonus item icon.
For Playdate: 1-bit graphics (black and white only).
"""

from PIL import Image, ImageDraw
import math
import os

# Icon dimensions (standard bonus item size)
ICON_SIZE = 32
CENTER = ICON_SIZE // 2

def draw_capacitor_symbol(draw, x, y, size):
    """Draw a capacitor circuit symbol."""
    half = size // 2
    gap = 3

    # Left plate
    draw.line([(x - half, y - half), (x - half, y + half)], fill=0, width=2)
    # Lead to left plate
    draw.line([(x - half - gap, y), (x - half, y)], fill=0, width=1)

    # Right plate
    draw.line([(x + half, y - half), (x + half, y + half)], fill=0, width=2)
    # Lead to right plate
    draw.line([(x + half, y), (x + half + gap, y)], fill=0, width=1)

def draw_shield_icon(draw, cx, cy, radius):
    """Draw a small shield arc."""
    segments = 12
    for i in range(segments // 2 + 1):
        # Draw top half arc
        angle = (i / segments) * 360 - 90  # Start from top
        a1 = angle - (180 / segments)
        a2 = angle + (180 / segments)

        x1 = cx + int(radius * math.cos(math.radians(a1)))
        y1 = cy + int(radius * math.sin(math.radians(a1)))
        x2 = cx + int(radius * math.cos(math.radians(a2)))
        y2 = cy + int(radius * math.sin(math.radians(a2)))

        draw.line([(x1, y1), (x2, y2)], fill=0, width=2)

def draw_energy_burst(draw, cx, cy, radius):
    """Draw energy burst lines radiating outward."""
    for i in range(8):
        angle = i * 45
        inner_r = radius - 2
        outer_r = radius + 3

        x1 = cx + int(inner_r * math.cos(math.radians(angle)))
        y1 = cy + int(inner_r * math.sin(math.radians(angle)))
        x2 = cx + int(outer_r * math.cos(math.radians(angle)))
        y2 = cy + int(outer_r * math.sin(math.radians(angle)))

        draw.line([(x1, y1), (x2, y2)], fill=0, width=1)

def generate_shield_capacitor():
    """Generate the Shield Capacitor bonus item icon."""
    img = Image.new('1', (ICON_SIZE, ICON_SIZE), 1)  # White background
    draw = ImageDraw.Draw(img)

    # Draw outer border (rounded rectangle style)
    draw.rectangle([1, 1, ICON_SIZE-2, ICON_SIZE-2], outline=0, width=1)

    # Draw shield arc at top
    draw_shield_icon(draw, CENTER, CENTER - 4, 10)

    # Draw capacitor symbol below
    draw_capacitor_symbol(draw, CENTER, CENTER + 6, 5)

    # Draw small energy dots around
    for angle in [45, 135]:
        x = CENTER + int(12 * math.cos(math.radians(angle)))
        y = CENTER + int(12 * math.sin(math.radians(angle)))
        draw.point((x, y), fill=0)

    return img

def generate_quantum_stabilizer():
    """Generate a Quantum Stabilizer bonus item icon (alternate design)."""
    img = Image.new('1', (ICON_SIZE, ICON_SIZE), 1)  # White background
    draw = ImageDraw.Draw(img)

    # Draw outer border
    draw.rectangle([1, 1, ICON_SIZE-2, ICON_SIZE-2], outline=0, width=1)

    # Draw atom-like orbital rings
    draw.ellipse([CENTER-10, CENTER-4, CENTER+10, CENTER+4], outline=0, width=1)
    draw.ellipse([CENTER-4, CENTER-10, CENTER+4, CENTER+10], outline=0, width=1)

    # Draw central nucleus
    draw.ellipse([CENTER-3, CENTER-3, CENTER+3, CENTER+3], fill=0)

    # Draw electron dots
    for angle in [0, 90, 180, 270]:
        x = CENTER + int(8 * math.cos(math.radians(angle)))
        y = CENTER + int(4 * math.sin(math.radians(angle)))
        draw.ellipse([x-1, y-1, x+1, y+1], fill=0)

    return img

def generate_power_relay():
    """Generate a Power Relay bonus item icon."""
    img = Image.new('1', (ICON_SIZE, ICON_SIZE), 1)  # White background
    draw = ImageDraw.Draw(img)

    # Draw outer border
    draw.rectangle([1, 1, ICON_SIZE-2, ICON_SIZE-2], outline=0, width=1)

    # Draw lightning bolt shape
    points = [
        (CENTER + 4, 6),
        (CENTER - 2, CENTER),
        (CENTER + 2, CENTER),
        (CENTER - 4, ICON_SIZE - 6),
        (CENTER + 2, CENTER + 2),
        (CENTER - 2, CENTER + 2),
    ]
    draw.polygon(points, fill=0)

    # Draw small circles at corners
    for x, y in [(6, 6), (ICON_SIZE-6, 6), (6, ICON_SIZE-6), (ICON_SIZE-6, ICON_SIZE-6)]:
        draw.ellipse([x-2, y-2, x+2, y+2], outline=0)

    return img

def main():
    output_dir = os.path.dirname(os.path.abspath(__file__))
    bonus_dir = os.path.join(output_dir, 'bonus_items')

    # Ensure output directory exists
    os.makedirs(bonus_dir, exist_ok=True)

    print("Generating bonus item assets...")

    # Generate Shield Capacitor
    shield_cap_img = generate_shield_capacitor()
    shield_cap_filename = os.path.join(bonus_dir, 'bonus_shield_capacitor.png')
    shield_cap_img.save(shield_cap_filename)
    print(f"  Created: bonus_shield_capacitor.png")

    # Generate Quantum Stabilizer (alternate bonus item)
    quantum_img = generate_quantum_stabilizer()
    quantum_filename = os.path.join(bonus_dir, 'bonus_quantum_stabilizer.png')
    quantum_img.save(quantum_filename)
    print(f"  Created: bonus_quantum_stabilizer.png")

    # Generate Power Relay
    power_img = generate_power_relay()
    power_filename = os.path.join(bonus_dir, 'bonus_power_relay.png')
    power_img.save(power_filename)
    print(f"  Created: bonus_power_relay.png")

    print("\nBonus item assets generated successfully!")
    print(f"Output directory: {bonus_dir}")
    print("\nNew bonus items:")
    print("  - Shield Capacitor: Upgrades station shield")
    print("  - Quantum Stabilizer: Reduces damage taken")
    print("  - Power Relay: Boosts all tools")

if __name__ == '__main__':
    main()
