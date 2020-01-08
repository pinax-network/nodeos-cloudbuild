# Build environments and images

## How to apply a patch

Create the file in `patches` directory.
Edit `Dockerfile-eos-full` and put the file name in _PATCHES (space separated, no directory path).
The, commit and push into git as `branch/default`, this will trigger the build.
Use the build ID (usually version_sha) to build `manageos`
