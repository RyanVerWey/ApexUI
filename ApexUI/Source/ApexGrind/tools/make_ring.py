"""Create addon-owned map area artwork: pale fill and an antialiased outline."""
from pathlib import Path
import math
import struct

size=128
pixels=bytearray()
for y in range(size):
    for x in range(size):
        distance=math.hypot(x-63.5,y-63.5)
        edge=max(0,min(1,2-abs(distance-60)))
        fill=.13 if distance<60 else 0
        pixels.extend((255,255,255,round(255*max(edge,fill))))
header=struct.pack('<BBBHHBHHHHBB',0,0,2,0,0,0,0,0,size,size,32,40)
(Path(__file__).resolve().parents[1]/'GrindArea.tga').write_bytes(header+pixels)
print('Generated GrindArea.tga')
