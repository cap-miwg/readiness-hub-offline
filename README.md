# CAP Readiness Hub - Offline Version

A standalone offline version of the CAP Readiness Hub that allows you to import CAPWATCH data and browse insights without requiring Google Apps Script.

## Try It Now

**[Launch the Readiness Hub](https://cap-miwg.github.io/readiness-hub-offline/)** — no installation required!

Simply upload your CAPWATCH ZIP file and start exploring your unit's readiness data. Your data is processed entirely in your browser and stored locally—nothing is sent to any server.

## Quick Start

### Option 1: Use the Pre-built Version
1. Open `index.html` in a modern web browser (Chrome, Firefox, Edge, Safari)
2. When prompted, upload your CAPWATCH export ZIP file
3. Browse your unit's readiness data offline

### Option 2: Build from Source
Run the PowerShell build script to generate a fresh `index.html` from the main repository:

```powershell
.\build.ps1
```

## Getting CAPWATCH Data

1. Log in to eServices at https://www.capnhq.gov
2. Navigate to **Administration** → **CAPWATCH Download**
3. Select your unit and data scope
4. Download the ZIP file
5. Import it into this offline app

## Features

All features from the main Readiness Hub are available:

- **Senior Dashboard**: Education & Training levels, specialty tracks, duty positions, ES qualifications
- **Cadet Dashboard**: Rank progression, phase tracking, promotion readiness
- **Unit Overview**: Staffing coverage, duty position analysis, ES team readiness
- **Org Chart**: Visual unit hierarchy with duty positions
- **Reports**: Filtered member lists, export capabilities

## Data Storage

- Your data is stored locally in your browser using IndexedDB
- No data is sent to any server
- Data persists between sessions until you clear browser data or import new data

## Technical Notes

- Requires a modern web browser with JavaScript enabled
- Uses CDN-hosted libraries (React, Tailwind CSS, JSZip)
- First load requires internet for CDN resources; subsequent offline use supported via browser cache

## File Structure

```
readiness-hub-offline/
├── index.html          # Main application (self-contained)
├── build.ps1           # Build script to regenerate from source
└── README.md           # This file
```

## Differences from Main Version

| Feature | Main (Google Apps Script) | Offline |
|---------|---------------------------|---------|
| Data Source | Google Drive sync | ZIP file import |
| Authentication | Google Account | None |
| Hosting | Google Apps Script | Local file / GitHub Pages |
| Updates | Automatic | Manual re-import |
| Feedback | GitHub Issues API | Not available |

## Troubleshooting

### "Cannot read file" error
- Ensure you're uploading a valid CAPWATCH ZIP file
- The ZIP should contain `.txt` files like `Member.txt`, `Organization.txt`, etc.

### Blank screen after import
- Open browser developer tools (F12) and check the Console for errors
- Try clearing browser data and re-importing

### Data not persisting
- Ensure you're not in private/incognito mode
- IndexedDB storage may be disabled in some browser configurations

## License

Same license as the main CAP Readiness Hub repository.
