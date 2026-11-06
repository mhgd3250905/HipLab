# Native alpha-unpack synthetic fixture

The two RGBA PNGs were rendered from the real Android renderer fragment shader on a headless EGL/GLES pbuffer using installed ANGLE (NVIDIA D3D11). Only the external-texture extension/sampler was adapted to sampler2D to feed the synthetic packed image. A trivial full-screen quad supplies canonical bottom-left UVs. Identity ST with vertically reversed upload and Y-flip ST with ordinary top-down upload both matched an independently constructed Pillow mask/CPU premultiplication oracle exactly in all channels, including thin lines and partial alpha96/160.

`receipt.json` records shader/source hashes, backend, adapter changes, cases and fixture hashes. PNGs store standard straight alpha (the GPU bytes were unpremultiplied solely for PNG encoding); Flutter decoding restores premultiplied Texture semantics. `reference-rgba.png` is the independent CPU oracle, not an alias of the sampled GPU output.

This establishes the shader math and supplies a separately generated GPU frame for the production Dart native-RGBA consumer's transform/clipping tests. It does not establish Android OES texture transport, MediaPlayer timing, SurfaceProducer lifecycle, physical-device output, iOS or FPS. Reproduction scripts and raw premultiplied bytes are retained in the ignored E-drive delivery artifacts; these fixtures are not App assets or APK content.
