"""One-time migration: only the 159 games linked by the existing catalogue."""
import concurrent.futures
import hashlib
import json
import os
from pathlib import Path
import subprocess
import time
from urllib.parse import quote

REPO = os.environ["GH_REPO"]
TAG = "android-games"
ROWS = json.loads(Path(".github/migration-game-apks.json").read_text())
assert len(ROWS) == 159 and len({row[0] for row in ROWS}) == 159
DEST = Path("migration-apks")
DEST.mkdir(exist_ok=True)


def api(endpoint, paginate=False):
    command = ["gh", "api"]
    if paginate:
        command += ["--paginate", "--slurp"]
    return json.loads(subprocess.check_output(command + [endpoint], text=True))


release = api(f"repos/{REPO}/releases/tags/{TAG}")
assert release["draft"], "Migration only writes to the prepared draft release"
assert not release["immutable"]
endpoint = f"repos/{REPO}/releases/{release['id']}/assets?per_page=100"
existing = {a["name"]: a for page in api(endpoint, True) for a in page}
assert set(existing) <= {row[0] for row in ROWS}, "Unexpected assets in migration release"


def download(row):
    name, size, etag = row
    assert Path(name).name == name
    target = DEST / name
    subprocess.run([
        "curl", "--fail", "--location", "--retry", "4", "--retry-all-errors",
        "--connect-timeout", "15", "--max-time", "180", "--silent", "--show-error",
        "--header", f"If-Match: {etag}", "--output", str(target),
        "https://moonbit-raylib-android-games.s3.us-west-2.amazonaws.com/" + quote(name),
    ], check=True)
    assert target.stat().st_size == size, name
    sha256 = hashlib.sha256()
    parts = []
    with target.open("rb") as file:
        while chunk := file.read(8 * 1024 * 1024):
            sha256.update(chunk)
            parts.append(hashlib.md5(chunk).digest())
    expected = etag.strip('"')
    actual = (hashlib.md5(b"".join(parts)).hexdigest() + f"-{len(parts)}"
              if "-" in expected else parts[0].hex())
    assert actual == expected, f"S3 ETag mismatch: {name}"
    return {"name": name, "size": size, "sha256": sha256.hexdigest(), "s3_etag": expected}


with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
    manifests = list(pool.map(download, ROWS))
print(f"Downloaded and verified {len(manifests)} APKs against S3 ETags.", flush=True)

for index, entry in enumerate(manifests, 1):
    asset = existing.get(entry["name"], {})
    digest = "sha256:" + entry["sha256"]
    if asset.get("state") == "uploaded" and asset.get("size") == entry["size"] and asset.get("digest") == digest:
        print(f"Already verified {index}/159: {entry['name']}", flush=True)
        continue
    for attempt in range(4):
        result = subprocess.run(["gh", "release", "upload", TAG, str(DEST / entry["name"]),
                                 "--repo", REPO, "--clobber"])
        if result.returncode == 0:
            break
        time.sleep(15 * (attempt + 1))
    else:
        raise RuntimeError("Upload failed: " + entry["name"])
    print(f"Uploaded {index}/159: {entry['name']}", flush=True)
    # Stay below GitHub's content-generation secondary rate limits.
    time.sleep(2)

assets = {a["name"]: a for page in api(endpoint, True) for a in page}
assert set(assets) == {entry["name"] for entry in manifests}
for entry in manifests:
    asset = assets[entry["name"]]
    assert asset["state"] == "uploaded", entry["name"]
    assert asset["size"] == entry["size"], entry["name"]
    assert asset["digest"] == "sha256:" + entry["sha256"], entry["name"]
Path("migration-manifest.json").write_text(json.dumps(manifests, indent=2) + "\n")
print("Verified all 159 GitHub assets against the source APKs. Release remains a draft.", flush=True)
