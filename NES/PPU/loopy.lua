-- Drawing PPU image .. Create 1d Array 


local loopy = {}
loopy.ppuStates = {}
loopy.course_x = 0x00
loopy.course_y = 0x00
loopy.nametable_x = 0x00
loopy.nametable_y = 0x00
loopy.fine_x = 0x00
loopy.fine_y = 0x00
loopy.unused = 0x00
loopy.reg = 0x000
loopy.scanLine = 0
loopy.drawScreen = false
loopy.drawSprites = false
loopy.register_vram_addr = 0x0000
loopy.register_tram_addr = 0x0000
loopy.sprite0HitOffset_x = 0x00
loopy.sprite0HitOffset_y = 0x00
loopy.startOffset_x = 0x00
loopy.startOffset_y = 0x00
loopy.startFineOffset_x = 0x00
loopy.startFineOffset_y = 0x00
loopy.sprite0Scanline = 0x00
loopy.startNamespace_x = 0x00
loopy.startNamespace_y = 0x00
loopy.sprite0Namespace_x = 0x00
loopy.sprite0Namespace_y = 0x00
loopy.preSrite0TileSet = {}
loopy.postSprite0TileSet = {}
loopy.preSprite0SpritePattern = 0
loopy.postSprite0SpritePattern = 0
loopy.preSprite0BackgroundPattern = 0
loopy.postSprite0BackgroundPattern = 0
loopy.prePPUAddress = 0x2000
loopy.postPPUAddress = 0x2000
loopy.inVBlank = false

return loopy