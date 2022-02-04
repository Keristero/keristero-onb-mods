# Installation
Numpy and Pillow python libraries are required

`pip install numpy`
`pip install Pillow` aka PIL

# Instructions
Run `python dump_palette.py battle.png 256`

Where the `png` is a single frame of megman with his palette swapped to ideal colors.
You'll need to replace the output palette (1x256 pixels) with the one in the `megaman/forms/` directory
The engine will then swap his palette out correctly.