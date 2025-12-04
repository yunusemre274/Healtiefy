"""
Generate Healtiefy logo and splash screen images
Modern, minimal iOS-style fitness app logo
"""
from PIL import Image, ImageDraw, ImageFilter
import math
import os

# Ensure output directory exists
output_dir = r"c:\Users\yunus\Desktop\Projects\Healtiefy\assets\images"
os.makedirs(output_dir, exist_ok=True)

# Colors - iOS Health/Activity style
NEON_GREEN = (50, 215, 75)      # #32D74B - iOS Activity green
WHITE = (255, 255, 255)         # #FFFFFF
DARK_BG = (10, 15, 15)          # #0A0F0F for splash


def draw_rounded_rect(draw, xy, radius, fill):
    """Draw a rounded rectangle with smooth corners"""
    x1, y1, x2, y2 = xy
    diameter = radius * 2
    
    # Main rectangles
    draw.rectangle([x1 + radius, y1, x2 - radius, y2], fill=fill)
    draw.rectangle([x1, y1 + radius, x2, y2 - radius], fill=fill)
    
    # Corner circles
    draw.ellipse([x1, y1, x1 + diameter, y1 + diameter], fill=fill)
    draw.ellipse([x2 - diameter, y1, x2, y1 + diameter], fill=fill)
    draw.ellipse([x1, y2 - diameter, x1 + diameter, y2], fill=fill)
    draw.ellipse([x2 - diameter, y2 - diameter, x2, y2], fill=fill)


def draw_walking_figure(draw, cx, cy, scale, color):
    """
    Draw a clean, minimal walking figure pictogram
    Similar to pedestrian/walking icons in fitness apps
    """
    # Scale factor for sizing
    s = scale
    
    # Head - circular
    head_radius = s * 0.09
    head_cy = cy - s * 0.32
    draw.ellipse([
        cx - head_radius, head_cy - head_radius,
        cx + head_radius, head_cy + head_radius
    ], fill=color)
    
    # Body - slightly angled torso
    body_width = int(s * 0.055)
    torso_top = (cx, cy - s * 0.22)
    torso_bottom = (cx + s * 0.02, cy + s * 0.08)
    draw.line([torso_top, torso_bottom], fill=color, width=body_width)
    
    # Arms
    arm_width = int(s * 0.045)
    shoulder = (cx, cy - s * 0.18)
    
    # Left arm (back) - angled backward and down
    left_hand = (cx - s * 0.14, cy + s * 0.02)
    draw.line([shoulder, left_hand], fill=color, width=arm_width)
    
    # Right arm (forward) - angled forward and up
    right_hand = (cx + s * 0.16, cy - s * 0.12)
    draw.line([shoulder, right_hand], fill=color, width=arm_width)
    
    # Legs
    leg_width = int(s * 0.05)
    hip = (cx + s * 0.02, cy + s * 0.08)
    
    # Left leg (back) - stepping back
    left_foot = (cx - s * 0.10, cy + s * 0.38)
    draw.line([hip, left_foot], fill=color, width=leg_width)
    
    # Right leg (forward) - stepping forward
    right_foot = (cx + s * 0.16, cy + s * 0.38)
    draw.line([hip, right_foot], fill=color, width=leg_width)


def create_main_logo(size=1024):
    """
    Create the main app logo:
    - White rounded square background
    - Green walking figure centered
    - Subtle shadow/glow effect
    """
    # Create larger canvas for shadow effect
    canvas_size = int(size * 1.1)
    img = Image.new('RGBA', (canvas_size, canvas_size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Calculate icon dimensions
    padding = (canvas_size - size) // 2
    icon_margin = size * 0.05
    icon_x1 = padding + icon_margin
    icon_y1 = padding + icon_margin
    icon_x2 = padding + size - icon_margin
    icon_y2 = padding + size - icon_margin
    
    # iOS-style corner radius (~22% of icon size)
    corner_radius = int(size * 0.22)
    
    # Draw shadow layer first (offset and blurred)
    shadow_img = Image.new('RGBA', (canvas_size, canvas_size), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow_img)
    shadow_offset = size * 0.015
    shadow_color = (0, 0, 0, 40)
    
    draw_rounded_rect(shadow_draw, 
        (icon_x1 + shadow_offset, icon_y1 + shadow_offset * 2, 
         icon_x2 + shadow_offset, icon_y2 + shadow_offset * 2),
        corner_radius, shadow_color)
    
    # Blur the shadow
    shadow_img = shadow_img.filter(ImageFilter.GaussianBlur(radius=size * 0.02))
    
    # Composite shadow onto main image
    img = Image.alpha_composite(img, shadow_img)
    draw = ImageDraw.Draw(img)
    
    # Draw white rounded square background
    draw_rounded_rect(draw, (icon_x1, icon_y1, icon_x2, icon_y2), corner_radius, WHITE)
    
    # Draw walking figure centered
    center_x = canvas_size // 2
    center_y = canvas_size // 2
    figure_scale = size * 0.55
    
    draw_walking_figure(draw, center_x, center_y, figure_scale, NEON_GREEN)
    
    # Crop to final size (removing extra canvas padding, keeping shadow)
    final_margin = int(size * 0.02)
    crop_box = (padding - final_margin, padding - final_margin, 
                padding + size + final_margin, padding + size + final_margin)
    img = img.crop(crop_box)
    
    # Resize to exact 1024x1024
    img = img.resize((size, size), Image.Resampling.LANCZOS)
    
    return img


def create_foreground_logo(size=1024):
    """
    Create foreground icon for Android adaptive icons
    Just the walking figure, centered in safe zone
    """
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    center = size // 2
    # Adaptive icons need content in center 66% (safe zone)
    safe_scale = size * 0.45
    
    draw_walking_figure(draw, center, center, safe_scale, NEON_GREEN)
    
    return img


def create_splash_logo(size=512):
    """
    Create splash screen logo
    Walking figure on transparent background (splash bg will be dark)
    """
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    center = size // 2
    figure_scale = size * 0.6
    
    # Draw the walking figure in green (will show on dark splash background)
    draw_walking_figure(draw, center, center, figure_scale, NEON_GREEN)
    
    return img

def main():
    print("Generating Healtiefy logo assets...")
def main():
    print("Generating Healtiefy logo assets...")
    print("Style: iOS-style rounded square with green walking figure")
    
    # Main logo (1024x1024)
    print("  Creating main logo (1024x1024)...")
    logo = create_main_logo(1024)
    logo.save(os.path.join(output_dir, "logo.png"))
    
    # Foreground for adaptive icons
    print("  Creating adaptive icon foreground (1024x1024)...")
    foreground = create_foreground_logo(1024)
    foreground.save(os.path.join(output_dir, "logo_foreground.png"))
    
    # Splash logo (512x512)
    print("  Creating splash logo (512x512)...")
    splash = create_splash_logo(512)
    splash.save(os.path.join(output_dir, "splash_logo.png"))
    
    # Create additional sizes for various uses
    sizes = [192, 512]
    for s in sizes:
        print(f"  Creating logo_{s}.png...")
        resized = logo.resize((s, s), Image.Resampling.LANCZOS)
        resized.save(os.path.join(output_dir, f"logo_{s}.png"))
    
    print("\n✓ All logo assets generated successfully!")
    print(f"  Output directory: {output_dir}")
    print("\nGenerated files:")
    for f in os.listdir(output_dir):
        if f.endswith('.png'):
            print(f"  - {f}")

if __name__ == "__main__":
    main()
