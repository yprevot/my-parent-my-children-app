"""Genera imágenes OCR con texto original, sin contenido de terceros.

Requiere Pillow. Ejemplo: .tooling/fixture-venv/bin/python scripts/generate_fixture.py
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

root = Path(__file__).resolve().parents[1] / "test_assets"
root.mkdir(exist_ok=True)
paragraphs = ["The cat is small.\nIt likes to play.", "We read a book together.\nLearning is an adventure."]
font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf", 64)
image = Image.new("RGB", (1600, 1100), "white")
draw = ImageDraw.Draw(image)
for index, paragraph in enumerate(paragraphs):
    draw.multiline_text((100, 160 + index * 320), paragraph, fill="black", font=font, spacing=30)
image.save(root / "learning_page.png")
(root / "learning_page.txt").write_text("\n\n".join(paragraphs) + "\n")
(root / "LICENSE.txt").write_text("Textos de prueba originales de MySchoolMyParents. CC0-1.0.\nLa fuente del sistema se usa al generar la imagen, no se distribuye.\n")
