# Asset credits and build behavior

Bundled original assets: procedural 1K diffuse/normal/roughness images (30 files), procedural articulated 3D characters (6 uniform colors x 4 hair choices), in-game props, weapon meshes, and code-driven animation. No PUBG or other proprietary game assets are included. No external animation files, motion capture, photoreal human models or actual screenshot renders are included.

Optional automatic build-time online assets (Poly Haven, CC0):
- https://polyhaven.com/a/metal_office_desk
- https://polyhaven.com/a/sofa_02
- https://polyhaven.com/a/wooden_crate_01
- https://polyhaven.com/a/concrete_floor_worn_001
- https://polyhaven.com/a/painted_plaster_wall
- https://polyhaven.com/a/floor_tiles_06
- https://polyhaven.com/a/raw_wooden_floor_01
- https://polyhaven.com/a/marble_01

Provider license: https://polyhaven.com/license. API terms: https://github.com/Poly-Haven/Public-API/blob/master/ToS.md. Downloader identifies itself and requests 1K model assets, 2K surface maps when available. Models are scaled to fit the existing authoritative map collision bounds; decorative geometry is not an exact collision mesh. Hospital furnishings remain original procedural models. Build artifact includes the generated manifest of successfully retrieved assets and hashes for downloaded dependencies. Build logs identify failures, and local procedural fallbacks keep the game buildable. The online downloads were not verified in the authoring environment (network unavailable); the actual downloaded files are not in this ZIP. For a build that refuses to continue if any remote asset is unavailable, run `python3 tools/fetch_hd_assets.py --strict` instead. Check any new third-party asset's license before redistributing it. No live asset API calls are made by the installed game.
