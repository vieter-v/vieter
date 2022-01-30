import random
import tempfile
import tarfile
from pathlib import Path
import uuid
import argparse
import asyncio
import aiohttp


# A list of words the program can choose from
WORDS = ["alpha", "bravo", "charlie", "delta", "echo", "foxtrot", "golf",
         "hotel", "india", "juliet", "kilo", "lima", "mike", "november",
         "oscar", "papa", "quebec", "romeo", "sierra", "tango", "uniform",
         "victor", "whiskey", "xray", "yankee", "zulu"]
SEED = 2022


def random_words(max_len=None, min_len=1):
    """
    Returns a random list of words, with a length randomly choosen between
    min_len and max_len. If max_len is None, it is equal to the length of
    WORDS.
    """
    if max_len is None:
        max_len = len(WORDS)

    k = random.randint(min_len, max_len)

    return random.choices(WORDS, k=k)

def random_lists(n, max_len=None, min_len=1):
    return [random_words(max_len, min_len) for _ in range(n)]

def create_random_pkginfo():
    """
    Generates a random .PKGINFO
    """
    name = "-".join(random_words(3))
    ver = "0.1.0"  # doesn't matter what it is anyways

    # TODO add random dependencies (all types)

    data = {
        "pkgname": name,
        "pkgbase": name,
        "pkgver": ver,
        "arch": "x86_64"
    }

    return "\n".join(f"{key} = {value}" for key, value in data.items())

def create_random_package(tmpdir):
    """
    Creates a random, but valid Arch package, using the provided tmpdir. Output
    is the path to the created package tarball.
    """

    sub_path = tmpdir / uuid.uuid4().hex
    sub_path.mkdir()

    tar_path = sub_path / "archive.pkg.tar.gz"

    def remove_prefix(tar_info):
        tar_info.name = tar_info.name[len(str(sub_path)):]

        return tar_info

    with tarfile.open(tar_path, "w") as tar:
        # Add random .PKGINFO file
        pkginfo_file = sub_path / ".PKGINFO"
        pkginfo_file.write_text(create_random_pkginfo())
        tar.add(pkginfo_file, filter=remove_prefix)

        # Create random files
        for words in random_lists(10, max_len=5):
            path = sub_path / 'usr' / ('/'.join(words) + ".txt")
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(' '.join(words))

            tar.add(path, filter=remove_prefix)

    return tar_path


async def upload_random_package(dir, sem):
    tar_path = create_random_package(dir)

    async with sem:
        with open(tar_path, 'rb') as f:
            async with aiohttp.ClientSession() as s:
                async with s.post("http://localhost:8000/publish", data=f.read(), headers={"x-api-key": "test"}) as r:
                    print(r.text)


async def main():
    parser = argparse.ArgumentParser(description="Test vieter by uploading random package files.")
    
    parser.add_argument("count", help="How many packages to upload.", default=1, type=int)
    parser.add_argument("-p", "--parallel", help="How many uploads to run in parallel.", default=1, type=int)
    parser.add_argument("-s", "--seed", help="Seed for the randomizer.", default=SEED, type=int)
    # parser.add_argument("-d", "--dir", help="Directory to create ")

    args = parser.parse_args()

    sem = asyncio.BoundedSemaphore(args.parallel)
    random.seed(args.seed)

    with tempfile.TemporaryDirectory() as tmpdirname:
        tmpdir = Path(tmpdirname)

        await asyncio.gather(*(upload_random_package(tmpdir, sem) for _ in range(args.count)))


if __name__ == "__main__":
    asyncio.run(main())
