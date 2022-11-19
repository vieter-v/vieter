# repo

This module manages the contents of the various repositories stored within a
Vieter instance.

## Terminology

* Arch-repository (arch-repo): specific architecture of a given repository. This is what
  Pacman actually uses as a repository, and contains its own `.db` & `.files`
  files.
* Repository (repo): a collection of arch-repositories. A single repository can
  contain packages of different architectures, with each package being stored
  in that specific architecture' arch-repository.
* Repository group (repo-group): a collection of repositories. Each Vieter
  instance consists of a single repository group, which manages all underlying
  repositories & arch-repositories.

## Arch-repository layout

An arch-repository (aka a regular Pacman repository) consists of a directory
with the following files (`{repo}` should be replaced with the name of the
repository):

* One or more package directories. These directories follow the naming scheme
  `${pkgname}-${pkgver}-${pkgrel}`. Each of these directories contains two
  files, `desc` & `files`. The `desc` file is a list of the package's metadata,
  while `files` contains a list of all files that the package contains. The
  latter is used when using `pacman -F`.
* `{repo}.db` & `{repo}.db.tar.gz`: the database file of the repository. This
  is just a compressed tarball of all package directories, but only their
  `desc` files. Both these files should have the same content (`repo-add`
  creates a symlink, but Vieter just serves the same file for both routes)
* `{repo}.files` & `{repo}.files.tar.gz`: the same as the `.db` file, but this
  also contains the `files` files, instead of just the `desc` files.

## Filesystem layout

The repository part of Vieter consists of two directories. One is the `repos`
directory inside the configured `data_dir`, while the other is the configured
`pkg_dir`. `repos` contains only the repository group, while `pkg_dir` contains
the actual package archives. `pkg_dir` is the directory that can take up a
significant amount of memory, while `repos` solely consists of small text
files.
