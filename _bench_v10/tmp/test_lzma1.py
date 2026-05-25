import lzma, hashlib

tests = [
    ("S5",  r"D:\DownloadsChrome\Takeout_Extracted_20260421T235753Z_3_001\Takeout\Minha atividade\Maps\Minhaatividade.json", "Maps-activity.json", 15297),
    ("S8",  r"D:\DownloadsChrome\Takeout_Extracted_20260421T235753Z_3_001\Takeout\Minha atividade\AI Mode\Minhaatividade.json", "AI Mode-activity.json", 71821),
    ("S11", r"D:\DownloadsChrome\Takeout_Extracted_20260421T235753Z_3_001\Takeout\Minha atividade\Google Play Store\Minhaatividade.json", "Google Play Store-activity.json", 11318),
]

for fid, path, name, A in tests:
    with open(path, 'rb') as f:
        data = f.read()
    sha_orig = hashlib.sha256(data).hexdigest()
    c    = lzma.compress(data, format=lzma.FORMAT_ALONE, preset=9|lzma.PRESET_EXTREME)
    dec  = lzma.decompress(c, format=lzma.FORMAT_ALONE)
    sha_dec = hashlib.sha256(dec).hexdigest()
    ovhd = 12 + 43 + len(name.encode())
    D = len(c) + ovhd
    rt = "OK" if sha_orig == sha_dec else "FAIL"
    print(f"{fid}  orig={len(data)}B  A={A}B  lzma1-ext={len(c)}B  D={D}  D-A={D-A:+d}  roundtrip={rt}")
