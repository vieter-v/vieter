import random
import tempfile
import tarfile
from pathlib import Path
import uuid
import argparse
import asyncio
import aiohttp
import sys


# A list of words the program can choose from
WORDS = ["alpha", "bravo", "charlie", "delta", "echo", "foxtrot", "golf",
         "hotel", "india", "juliet", "kilo", "lima", "mike", "november",
         "oscar", "papa", "quebec", "romeo", "sierra", "tango", "uniform",
         "victor", "whiskey", "xray", "yankee", "zulu"]
SEED = 2022


def random_words(words, min_len, max_len=None):
    """
    Returns a random list of words, with a length randomly choosen between
    min_len and max_len. If max_len is None, it is equal to the length of
    words.
    """
    if max_len is None:
        max_len = len(words)

    k = random.randint(min_len, max_len)

    return random.choices(words, k=k)

def random_lists(words, n, min_len, max_len=None):
    return [random_words(words, min_len, max_len) for _ in range(n)]

def create_random_pkginfo(words, name_min_len, name_max_len):
    """
    Generates a random .PKGINFO
    """
    name = "-".join(random_words(words, name_min_len, name_max_len))
    ver = "0.1.0-3"  # doesn't matter what it is anyways

    # TODO add random dependencies (all types)

    data = {
        "pkgname": name,
        "pkgbase": name,
        "pkgver": ver,
        "arch": "x86_64"
    }

    return "\n".join(f"{key} = {value}" for key, value in data.items())

def create_random_package(tmpdir, words, pkg_name_min_len, pkg_name_max_len, min_files, max_files, min_filename_len, max_filename_len):
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

    with tarfile.open(tar_path, "w:gz") as tar:
        # Add random .PKGINFO file
        pkginfo_file = sub_path / ".PKGINFO"
        pkginfo_file.write_text(create_random_pkginfo(words, pkg_name_min_len, pkg_name_max_len))
        tar.add(pkginfo_file, filter=remove_prefix)

        # Create random files
        file_count = random.randint(min_files, max_files)

        for words in random_lists(words, file_count, min_filename_len, max_filename_len):
            path = sub_path / 'usr' / ('/'.join(words) + ".txt")
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(' '.join(words))

            tar.add(path, filter=remove_prefix)

    return tar_path


async def check_output(r):
    good = {"File already exists.", "Package added successfully."}
    txt = await r.text()

    return (txt in good, txt)


async def upload_random_package(tar_path, sem):
    async with sem:
        with open(tar_path, 'rb') as f:
            async with aiohttp.ClientSession() as s:
                async with s.post("http://localhost:8000/vieter/publish", data=f.read(), headers={"x-api-key": "test"}) as r:
                    return await check_output(r)


async def main():
    parser = argparse.ArgumentParser(description="Test vieter by uploading random package files.")
    
    parser.add_argument("count", help="How many packages to upload.", default=1, type=int)
    parser.add_argument("-p", "--parallel", help="How many uploads to run in parallel.", default=1, type=int)
    parser.add_argument("-s", "--seed", help="Seed for the randomizer.", default=SEED, type=int)
    parser.add_argument("--min-files", help="Minimum amount of files to add to an archive.", default=5, type=int)
    parser.add_argument("--max-files", help="Max amount of files to add to an archive.", default=10, type=int)
    parser.add_argument("--min-filename-length", help="Minimum amount of words to use for generating filenames.", default=1, type=int)
    parser.add_argument("--max-filename-length", help="Max amount of words to use for generating filenames.", default=5, type=int)
    parser.add_argument("--min-pkg-name-length", help="Minimum amount of words to use for creating package name.", default=1, type=int)
    parser.add_argument("--max-pkg-name-length", help="Max amount of words to use for creating package name.", default=3, type=int)
    parser.add_argument("--words", help="Words to use for randomizing.", default=WORDS, type=lambda s: s.split(','))
    # parser.add_argument("--words", help="Words to use for randomizing.", default=WORDS, type=)
    # parser.add_argument("-d", "--dir", help="Directory to create ")

    args = parser.parse_args()

    sem = asyncio.BoundedSemaphore(args.parallel)
    random.seed(args.seed)


    with tempfile.TemporaryDirectory() as tmpdirname:
        tmpdir = Path(tmpdirname)

        # We generate the tars in advance because they're not async anyways
        print("Generating tarballs...")
        tars = {
            create_random_package(tmpdir, args.words, args.min_pkg_name_length, args.max_pkg_name_length, args.min_files, args.max_files, args.min_filename_length, args.max_filename_length)
            for _ in range(args.count)
        }

        print("Sending requests...")
        res = await asyncio.gather(*(upload_random_package(tar, sem) for tar in tars))

        # Generate status report
        if any(not x[0] for x in res):
            sys.exit(1)


if __name__ == "__main__":
    asyncio.run(main())
