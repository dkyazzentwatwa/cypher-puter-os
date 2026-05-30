# Samples

Place short mono PCM WAV files here. The starter kit expects:

```text
samples/drums/kick01.wav
samples/drums/snare01.wav
samples/drums/hat_closed.wav
samples/drums/hat_open.wav
samples/drums/clap.wav
samples/drums/tom.wav
samples/drums/rim.wav
samples/drums/shaker.wav
```

Recommended conversion:

```sh
ffmpeg -i input.wav -ac 1 -ar 22050 -sample_fmt s16 output.wav
```

Use shorter one-shots first: 50-200 ms hats, 150-500 ms kicks/snares/claps.
