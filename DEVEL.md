
# Development

How to push things forward. :)

## Build Matrix

Since we are striving for supporting multiple PHP versions and OS vendors we
span a matrix constituted by the `./Dockerfile`. This file is being evaluated
as template and a few variables - mostly governing which base image to derive
from - are being substituted.

## Development and Release Procedure

In order to work on a new version, a common procedure looks like the following:

### Implementation and Testing

* Manually increment ./VERSION and append `-devel` like `0.9.4-devel` which
  indicates that we are working on the next upcoming version and to be able to
  refer to this image for testing purposes.
* Make your changes to the source code
* Build the image: `./scripts/build.sh`
* Test against the demoshop
    * Checkout the repo under https://github.com/claranet/spryker-demoshop
    * Change the `FROM` line of the demoshop `Dockerfile` to the devel version
      from above `0.9.4-devel`
    * Build the demoshop: `./docker/run build`
    * Test the demoshop: `./docker/run devel up`

### Release

If all went well and your reached your desired state, then release this image:

* Revert the temporary development version: `git checkout VERSION`
* Commit your changes grouped by functional pieces!
* Do not forget to update the `CHANGELOG.md` file
* Keep in mind principles of semantic versioning:
    * PATCH version when you make backwards-compatible bug fixes
    * MINOR version when you add functionality in a backwards-compatible manner
    * MAJOR version when you make incompatible API changes
* Use the `./scripts/bump,sh` to release a new version which does the following for you:
    * Read `VERSION` and increment either patch, minor or major digit; If you
      call this script without arguments by default the patch digit will be
      incremented; otherwise you must specify either `major` or `minor` as
      argument.
    * Iterates a given set of files where the old version string will be
      replaced with the new one
    * Commits these changes with proper commit msg
    * Tags this commit
* Check of everything went well
* Push changes
    * `git push`
    * `git push --tags`
* Check if CI system builds correctly: https://travis-ci.org/claranet/spryker-base/branches
