# Build script for CAP Readiness Hub Offline
# This script combines all source files into a single standalone HTML file

$sourceDir = ""
$outputDir = ""
$outputFile = "$outputDir\index.html"

# Order matters - dependencies must be loaded first
$fileOrder = @(
    # Styles
    "Styles.html",

    # Config & Constants (must load first)
    "ConfigConstants.html",
    "ConfigPromotionRules.html",

    # Utilities (dependencies for services)
    "UtilsDataParsing.html",
    "UtilsDateHelpers.html",
    "UtilsCadetHelpers.html",

    # Services (depend on utilities and config)
    "ServicesDataService.html",
    "ServicesCadetDataService.html",
    "ServicesESDataService.html",
    "ServicesESUnitAnalysisService.html",
    "ServicesOrgStatsDataService.html",

    # Components (depend on services)
    "ComponentsCore.html",
    "ComponentsLevelIndicator.html",
    "ComponentsFilters.html",
    "ComponentsESDisplay.html",
    "ComponentsCadetComponents.html",
    "ComponentsOrgNode.html",

    # Modals (depend on components)
    "ModalLevelDetail.html",
    "ModalPromotionCriteria.html",
    "ModalSeniorProfile.html",
    "ModalCadetProfile.html",
    "ModalDrillDownPosition.html",
    "ModalESQualification.html",
    "ModalESSkillTree.html",
    "ModalESReadiness.html",
    "ModalRecruitingRetention.html",
    "ModalReference.html",

    # App Sections (depend on modals and components)
    "AppHome.html",
    "AppSeniorDashboard.html",
    "AppCadetDashboard.html",
    "AppUnitOverview.html",
    "AppOrgChart.html",
    "AppReports.html",

    # Main App (last - depends on everything)
    "Index.html"
)

# ZIP file mapping from Code.gs
$fileMapJs = @"
// File mapping from CAPWATCH exports to payload structure
// Based on Code.gs lines 162-200
// Attach to window so it's accessible from Babel-transpiled scripts
window.CAPWATCH_FILE_MAP = {
  // Config files (use contains matching - these names are unique enough)
  'PL_Paths': { cat: 'config', key: 'paths' },
  'PL_Groups': { cat: 'config', key: 'groups' },
  'PL_Tasks': { cat: 'config', key: 'tasks' },
  'PL_TaskGroupAssignments': { cat: 'config', key: 'assignments' },
  'CdtAchvEnum': { cat: 'config', key: 'cadetAchvEnum' },
  'AchvStepTasks': { cat: 'config', key: 'esAchvStepTasks' },
  'AchvStepAchv': { cat: 'config', key: 'esAchvStepAchv' },
  // Data files (use contains matching - these names are unique enough)
  'CadetDutyPositions': { cat: 'data', key: 'cadetDuty' },
  'SeniorLevel': { cat: 'data', key: 'seniorLevels' },
  'SpecTrack': { cat: 'data', key: 'tracks' },
  'MbrCommittee': { cat: 'data', key: 'committees' },
  'MbrContact': { cat: 'data', key: 'contacts' },
  'MbrAchievements': { cat: 'data', key: 'esMbrAchievements' },
  'MbrTasks': { cat: 'data', key: 'esMbrTasks' },
  'PL_MemberTaskCredit': { cat: 'data', key: 'memberTasks' },
  'PL_MemberPathCredit': { cat: 'data', key: 'memberPaths' },
  'CadetRank': { cat: 'data', key: 'cadetRank' },
  'CadetAchvAprs': { cat: 'data', key: 'cadetAchvAprs' },
  'CadetAchvFullReport': { cat: 'data', key: 'cadetAchvFullReport' },
  'CadetActivities': { cat: 'data', key: 'cadetActivities' },
  'CadetHFZInformation': { cat: 'data', key: 'cadetHFZ' },
  'CadetPhase': { cat: 'data', key: 'cadetPhase' },
  'CadetAwards': { cat: 'data', key: 'cadetAwards' },
  'SeniorAwards': { cat: 'data', key: 'seniorAwards' },
  'OFlight': { cat: 'data', key: 'oFlights' },
  'ORGStatistics': { cat: 'data', key: 'orgStats' },
  'PL_VolUInstructors': { cat: 'data', key: 'voluInstructors' }
};

// Special handling for files that need exact matching vs contains matching
// These files have names that are substrings of other files, so we must match exactly
window.EXACT_MATCH_FILES = {
  'Achievements': { cat: 'config', key: 'esAchievements' },
  'Tasks': { cat: 'config', key: 'esTasks' },
  'CadetAchv': { cat: 'data', key: 'cadetAchv' },
  'Member': { cat: 'data', key: 'members' },
  'Organization': { cat: 'data', key: 'organization' },
  'DutyPosition': { cat: 'data', key: 'duty' },
  'Training': { cat: 'data', key: 'training' },
  'DownLoadDate': { cat: 'meta', key: 'downloadDate' }
};
"@

# IndexedDB wrapper
$indexedDbWrapper = @"
// IndexedDB wrapper for offline data persistence
// Attach to window so it's accessible from Babel-transpiled scripts
window.CapwatchDB = {
  DB_NAME: 'capwatch-offline',
  DB_VERSION: 1,
  STORE_NAME: 'data',

  async open() {
    return new Promise((resolve, reject) => {
      const request = indexedDB.open(this.DB_NAME, this.DB_VERSION);
      request.onerror = () => reject(request.error);
      request.onsuccess = () => resolve(request.result);
      request.onupgradeneeded = (event) => {
        const db = event.target.result;
        if (!db.objectStoreNames.contains(this.STORE_NAME)) {
          db.createObjectStore(this.STORE_NAME);
        }
      };
    });
  },

  async save(payload) {
    const db = await this.open();
    return new Promise((resolve, reject) => {
      const tx = db.transaction(this.STORE_NAME, 'readwrite');
      const store = tx.objectStore(this.STORE_NAME);
      const request = store.put({ payload, timestamp: Date.now() }, 'current');
      request.onerror = () => reject(request.error);
      request.onsuccess = () => resolve();
      tx.oncomplete = () => db.close();
    });
  },

  async load() {
    try {
      const db = await this.open();
      return new Promise((resolve, reject) => {
        const tx = db.transaction(this.STORE_NAME, 'readonly');
        const store = tx.objectStore(this.STORE_NAME);
        const request = store.get('current');
        request.onerror = () => reject(request.error);
        request.onsuccess = () => resolve(request.result);
        tx.oncomplete = () => db.close();
      });
    } catch (e) {
      console.warn('IndexedDB load failed:', e);
      return null;
    }
  },

  async clear() {
    const db = await this.open();
    return new Promise((resolve, reject) => {
      const tx = db.transaction(this.STORE_NAME, 'readwrite');
      const store = tx.objectStore(this.STORE_NAME);
      const request = store.clear();
      request.onerror = () => reject(request.error);
      request.onsuccess = () => resolve();
      tx.oncomplete = () => db.close();
    });
  }
};
"@

# ZIP import function - avoiding template literals to prevent PowerShell escaping issues
$zipImporter = @"
// Import CAPWATCH ZIP file and extract data
// Attach to window so it's accessible from Babel-transpiled scripts
window.importCapwatchZip = async function(file, onProgress) {
  try {
    onProgress && onProgress('Reading ZIP file...');
    const zip = await JSZip.loadAsync(file);

    const payload = {
      config: {},
      data: {},
      meta: {
        lastUpdated: new Date().toISOString(),
        source: 'zip-import',
        filename: file.name
      }
    };

    const entries = Object.entries(zip.files).filter(([_, entry]) => !entry.dir);
    let processed = 0;

    for (const [filename, zipEntry] of entries) {
      const baseName = filename.split('/').pop().replace('.txt', '');

      // Try exact match files first
      for (const [searchKey, def] of Object.entries(window.EXACT_MATCH_FILES)) {
        if (baseName === searchKey) {
          onProgress && onProgress('Processing ' + baseName + '...');
          const content = await zipEntry.async('string');
          payload[def.cat][def.key] = content;
          break;
        }
      }

      // Then try contains matching
      for (const [searchKey, def] of Object.entries(window.CAPWATCH_FILE_MAP)) {
        if (baseName.includes(searchKey)) {
          // Check exclusions
          if (def.exclude && def.exclude.some(ex => baseName.includes(ex))) continue;

          onProgress && onProgress('Processing ' + baseName + '...');
          const content = await zipEntry.async('string');
          payload[def.cat][def.key] = content;
          break;
        }
      }

      processed++;
      if (processed % 5 === 0) {
        onProgress && onProgress('Processed ' + processed + '/' + entries.length + ' files...');
      }
    }

    // Parse DownLoadDate if present and use it as lastUpdated
    if (payload.meta.downloadDate) {
      const lines = payload.meta.downloadDate.split('\n').filter(l => l.trim());
      if (lines.length > 1) {
        // Second line contains the date, strip quotes
        const dateStr = lines[1].replace(/"/g, '').trim();
        const parsed = new Date(dateStr);
        if (!isNaN(parsed.getTime())) {
          payload.meta.lastUpdated = parsed.toISOString();
        }
      }
    }

    onProgress && onProgress('Saving to local storage...');
    await window.CapwatchDB.save(payload);

    return payload;
  } catch (error) {
    console.error('ZIP import failed:', error);
    throw error;
  }
}
"@

# ZIP Import Modal Component - avoiding template literals
$zipImportModal = @"
// ZIP Import Modal Component
function ZipImportModal({ onImport, onClose, isOpen }) {
  const [dragOver, setDragOver] = React.useState(false);
  const [importing, setImporting] = React.useState(false);
  const [progress, setProgress] = React.useState('');
  const [error, setError] = React.useState(null);
  const fileInputRef = React.useRef(null);

  if (!isOpen) return null;

  const handleFile = async (file) => {
    if (!file || !file.name.toLowerCase().endsWith('.zip')) {
      setError('Please select a valid ZIP file');
      return;
    }

    setImporting(true);
    setError(null);
    setProgress('Starting import...');

    try {
      const payload = await window.importCapwatchZip(file, setProgress);
      setProgress('Import complete!');
      setTimeout(() => {
        onImport(payload);
      }, 500);
    } catch (err) {
      setError('Import failed: ' + err.message);
      setImporting(false);
    }
  };

  const handleDrop = (e) => {
    e.preventDefault();
    setDragOver(false);
    const file = e.dataTransfer.files[0];
    handleFile(file);
  };

  const handleDragOver = (e) => {
    e.preventDefault();
    setDragOver(true);
  };

  // Compute className without template literal to avoid PowerShell escaping issues
  const baseClass = "border-2 border-dashed rounded-xl p-8 text-center cursor-pointer transition-colors";
  const activeClass = dragOver ? "border-blue-500 bg-blue-50" : "border-slate-300 hover:border-blue-400 hover:bg-slate-50";
  const dropZoneClass = baseClass + " " + activeClass;

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-xl p-6 max-w-lg w-full shadow-2xl">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-xl font-bold text-slate-900">Import CAPWATCH Data</h2>
          {onClose && !importing && (
            <button onClick={onClose} className="text-slate-400 hover:text-slate-600">
              <Icon name="X" className="w-5 h-5" />
            </button>
          )}
        </div>

        <p className="text-sm text-slate-600 mb-4">
          Upload your CAPWATCH export ZIP file to load member data.
          The file is processed locally in your browser and stored offline.
        </p>

        {error && (
          <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg text-red-700 text-sm">
            {error}
          </div>
        )}

        {importing ? (
          <div className="text-center py-8">
            <div className="animate-spin rounded-full h-12 w-12 border-4 border-blue-500 border-t-transparent mx-auto mb-4"></div>
            <p className="text-sm text-slate-600">{progress}</p>
          </div>
        ) : (
          <div
            className={dropZoneClass}
            onDragOver={handleDragOver}
            onDragLeave={() => setDragOver(false)}
            onDrop={handleDrop}
            onClick={() => fileInputRef.current?.click()}
          >
            <Icon name="Upload" className="mx-auto h-12 w-12 text-slate-400 mb-4" />
            <p className="text-slate-600 font-medium">Drop your CAPWATCH export ZIP file here</p>
            <p className="text-sm text-slate-400 mt-2">or click to browse</p>
          </div>
        )}

        <input
          ref={fileInputRef}
          type="file"
          accept=".zip"
          className="hidden"
          onChange={(e) => handleFile(e.target.files[0])}
        />

        <div className="mt-4 text-xs text-slate-400 text-center">
          Data is stored locally in your browser using IndexedDB
        </div>
      </div>
    </div>
  );
}
"@

Write-Host "Building CAP Readiness Hub Offline..." -ForegroundColor Cyan

# Start HTML document
$html = @"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>CAP Readiness Hub - Offline</title>

  <!-- React -->
  <script src="https://unpkg.com/react@18/umd/react.production.min.js" crossorigin></script>
  <script src="https://unpkg.com/react-dom@18/umd/react-dom.production.min.js" crossorigin></script>
  <script src="https://unpkg.com/@babel/standalone/babel.min.js"></script>

  <!-- Tailwind CSS -->
  <script src="https://cdn.tailwindcss.com"></script>

  <!-- Lucide Icons (React version - same as original app) -->
  <script src="https://cdnjs.cloudflare.com/ajax/libs/lucide/0.263.1/lucide-react.min.js"></script>

  <!-- JSZip for ZIP file handling -->
  <script src="https://cdnjs.cloudflare.com/ajax/libs/jszip/3.10.1/jszip.min.js"></script>

  <!-- PDF/Canvas for reports -->
  <script src="https://cdnjs.cloudflare.com/ajax/libs/html2canvas/1.4.1/html2canvas.min.js"></script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js"></script>

  <!-- Chart.js -->
  <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body class="bg-slate-100">
  <div id="root"></div>

  <!-- Offline Data Handling -->
  <script>
  $fileMapJs

  $indexedDbWrapper

  $zipImporter
  </script>

"@

# Process each source file
foreach ($file in $fileOrder) {
    $filePath = Join-Path $sourceDir $file
    if (Test-Path $filePath) {
        Write-Host "  Adding $file..." -ForegroundColor Gray
        $content = Get-Content $filePath -Raw

        if ($file -eq "Index.html") {
            # Special handling for Index.html - need to modify it for offline use
            # Extract just the script content and modify the data loading flow

            # First, try to extract just the main script section
            if ($content -match '<script type="text/babel">([\s\S]*)</script>\s*</body>') {
                $scriptContent = $Matches[1]

                # Replace the loadData function with offline-aware version
                # This replacement adds ZIP import modal and IndexedDB loading
                $offlineLoadData = @'
          const loadData = async () => {
            // First, check IndexedDB for cached data
            const cached = await window.CapwatchDB.load();
            if (cached && cached.payload) {
              setLoadingStatus("Loading cached data...");
              processPayload(cached.payload);
              setLoading(false);
              return;
            }

            // No cached data - show ZIP import modal
            setLoading(false);
            setShowZipImportModal(true);
          };
          loadData();
'@

                # Replace the original loadData block
                $scriptContent = $scriptContent -replace 'const loadData = \(\) => \{[\s\S]*?fetchFromServer\(\);[\s\S]*?\};[\s\S]*?loadData\(\);', $offlineLoadData

                # Add showZipImportModal state
                $scriptContent = $scriptContent -replace '(\s+const \[loading, setLoading\] = useState\(true\);)', "`$1`n        const [showZipImportModal, setShowZipImportModal] = useState(false);"

                # Comment out google.script.run related code in fetchFromServer
                $scriptContent = $scriptContent -replace 'if \(window\.google && window\.google\.script\)', 'if (false /* Disabled for offline mode */)'

                # Add handleZipImport callback after the useState declarations
                # Use a more flexible pattern that handles nested parentheses in the useState call
                $handleZipImport = @'

        // Handle ZIP import completion
        const handleZipImport = useCallback((payload) => {
          setShowZipImportModal(false);
          setLoading(true);
          setLoadingStatus("Processing imported data...");
          processPayload(payload);
          setLoading(false);
        }, [processPayload]);

'@
                # Match isMobile useState with arrow function containing nested parens
                $scriptContent = $scriptContent -replace "(const \[isMobile, setIsMobile\] = useState\(\(\) => window\.matchMedia\('\(max-width: 768px\)'\)\.matches\);)", "`$1`n$handleZipImport"

                # Add ZipImportModal to the return statement - look for the last closing div before the return statement ends
                $zipModalJsx = @'

            {/* ZIP Import Modal */}
            {showZipImportModal && (
              <ZipImportModal
                isOpen={showZipImportModal}
                onImport={handleZipImport}
                onClose={null}
              />
            )}
'@
                # Insert the modal before the final closing </div> of the return block
                $scriptContent = $scriptContent -replace '(\s+\)\}\s*\)\}\s*</div>\s*\);)', "$zipModalJsx`$1"

                # Add Import button to desktop navigation
                $desktopImportBtn = @'
                   <button
                     onClick={() => setShowZipImportModal(true)}
                     className="px-3 py-1.5 rounded text-sm font-semibold whitespace-nowrap transition-all text-green-300 hover:text-white hover:bg-green-600 flex items-center gap-1"
                     title="Import new CAPWATCH data"
                   >
                     <Icon name="Upload" className="w-4 h-4" /> Import
                   </button>
                 </nav>
'@
                $scriptContent = $scriptContent -replace '(\s+\)\}\)\s*</nav>)', $desktopImportBtn

                # Add Import button to mobile navigation
                $mobileImportBtn = @'
                  <button
                    onClick={() => {
                      setShowZipImportModal(true);
                      setIsNavOpen(false);
                    }}
                    className="px-3 py-2 rounded text-sm font-semibold text-left transition-colors text-green-300 hover:bg-green-600 flex items-center gap-2"
                  >
                    <Icon name="Upload" className="w-4 h-4" /> Import Data
                  </button>
                </div>
              )}
'@
                $scriptContent = $scriptContent -replace '(\s+</div>\s*\)\}\s*\)\})\s*</header>', "$mobileImportBtn`n            </header>"

                # Update header to show OFFLINE badge
                $scriptContent = $scriptContent -replace 'MIWG Readiness</h1>', 'MIWG Readiness <span className="text-xs font-normal bg-green-600 text-white px-1.5 py-0.5 rounded ml-1">OFFLINE</span></h1>'
                $scriptContent = $scriptContent -replace 'Sync: \{formatSyncTime\(lastUpdated\)\}', 'Data: {lastUpdated ? formatSyncTime(lastUpdated) : ''Not loaded''}'

                # Wrap with modified App
                $html += @"

  <!-- Main Application (Modified for Offline) -->
  <script type="text/babel">
  $scriptContent
  </script>

"@
            } else {
                # Fallback: include as-is (shouldn't happen)
                Write-Host "    WARNING: Could not extract script from Index.html" -ForegroundColor Yellow
                $html += $content + "`n"
            }
        } elseif ($file -eq "ComponentsOrgNode.html") {
            # OrgNode needs to be exposed globally for OrgChartSection to use it
            $content = $content -replace '</script>', "// Expose OrgNode globally for use in other script blocks`nwindow.OrgNode = OrgNode;`n</script>"
            $html += $content + "`n"
        } elseif ($file -eq "AppOrgChart.html") {
            # OrgChartSection needs to get OrgNode from window
            $content = $content -replace 'function OrgChartSection\(props\) \{', "function OrgChartSection(props) {`n  // Get OrgNode from window (defined in separate script block)`n  const OrgNode = window.OrgNode;`n"
            $html += $content + "`n"
        } elseif ($file -eq "ComponentsCore.html") {
            # Add ComponentsCore first, then add ZipImportModal after it
            $html += $content + "`n"

            # Now add ZipImportModal since Icon is now defined
            $html += @"

  <!-- ZIP Import Modal (added after ComponentsCore which defines Icon) -->
  <script type="text/babel">
  $zipImportModal
  </script>

"@
        } else {
            # For all other files, just include the content directly
            $html += $content + "`n"
        }
    } else {
        Write-Host "  WARNING: $file not found!" -ForegroundColor Yellow
    }
}

# Close HTML document
$html += @"
</body>
</html>
"@

# Write output file
$html | Out-File -FilePath $outputFile -Encoding UTF8

Write-Host ""
Write-Host "Build complete!" -ForegroundColor Green
Write-Host "Output: $outputFile" -ForegroundColor Cyan
Write-Host ""
Write-Host "To use:" -ForegroundColor Yellow
Write-Host "  1. Open index.html in a web browser" -ForegroundColor White
Write-Host "  2. Import your CAPWATCH ZIP file when prompted" -ForegroundColor White
Write-Host "  3. Browse your unit's readiness data offline" -ForegroundColor White
