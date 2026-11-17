"""Generate the addon-owned transparent area outline as an uncompressed TGA."""
from pathlib import Path
import math
import struct

size = 128
header = struct.pack('<BBBHHBHHHHBB', 0, 0, 2, 0, 0, 0, 0, 0, size, size, 32, 40)
pixels = bytearray()
for y in range(size):
    for x in range(size):
        radius = math.hypot(x - 63.5, y - 63.5)
        alpha = round(255 * max(0, min(1, 2.5 - abs(radius - 60))))
        pixels.extend((255, 255, 255, alpha))
(Path(__file__).resolve().parents[1] / 'Ring.tga').write_bytes(header + pixels)
