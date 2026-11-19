# GAF external assets package

This folder contains the external asset tree extracted from the supplied `main.lua`.

## GitHub setup
1. Create a public GitHub repository (or a public folder in an existing repository).
2. Upload the **contents** of this folder, preserving all subfolders and file names.
3. Ensure `index.json` is at the repository root for the selected folder.
4. The raw base URL must point to that root, for example:
   `https://raw.githubusercontent.com/USERNAME/REPOSITORY/BRANCH/`

The GAF loader already supports a remote asset root via `GLOBAL.VISUALS_REMOTE`. After you send me the repository URL, I will wire the exact raw URL into the merged script and remove its embedded asset payload.

The `index.json` manifest lists each asset and its expected byte size. Assets are fetched individually and cached by the existing remote loader; the entire package is not downloaded at startup.
