from pathlib import Path
import re
import zipfile

root = Path(__file__).resolve().parent
addon = root / "PeaceAndQuiet"
toc = (addon / "PeaceAndQuiet.toc").read_text()
version = re.search(r"^## Version: ([0-9.]+)$", toc, re.M).group(1)
destination = root / "dist" / f"PeaceAndQuiet-{version}-Forever.zip"
destination.parent.mkdir(exist_ok=True)
with zipfile.ZipFile(destination, "w", zipfile.ZIP_DEFLATED) as archive:
    for path in sorted(addon.rglob("*")):
        if path.is_file():
            archive.write(path, path.relative_to(root))
print(destination)
