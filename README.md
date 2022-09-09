# dbz-bt3

A WIP disassembly (and maybe decomp in the future) of Dragon Ball Z: Budokai Tenkaichi 3.

This repo was created mainly to test PS2 compatibility with splat <https://github.com/AngheloAlf/splat/tree/ps2>, because of this, splat is not included in this repo and should be clonned manually.

For Python dependencies:

```bash
pip install -r requirements.txt
```

## Usage

- Place the `slus_216.78` file from the USA iso into the empty `SLUS_21678` folder.
- Set up tools and disassemble the image: `make setup SPLAT=path/to/splat/split.py`
- Assemble the image: `make`
