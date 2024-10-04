# Clear-CCMCache PowerShell Script

## Overview

The Clear-CCMCache PowerShell script is designed to remove old and unused content from the CCMCache folder used by the Microsoft System Center Configuration Manager (SCCM). This folder contains files that are downloaded by SCCM for various installations, including applications, patches, and task sequences.

The script uses Windows Management Instrumentation (WMI) to detect and remove items from the CCMCache folder that have not been referenced for a specified number of days.

## Usage

To use the script, open a PowerShell prompt and navigate to the directory where the script file is located. Then, enter one of the following command line options:

```powershell
.\Clear-CCMCache.ps1 [-Detect] [-Clean] [-Help] [-Days ##]
```

- `-Detect`: Detects old and unused content in the CCMCache folder and reports the results.
- `-Clean`: Cleans old and unused content from the CCMCache folder. If no option is provided, this is the default behavior.
- `-Help`: Shows the help message with information about the available options.
- `-Days`: Sets the number of days to keep files in the CCMCache folder. The default value is 30 days. This option can be used with both the `-Detect` and `-Clean` options.

For example, to clean content older than 14 days, run the following command:

```powershell
.\Clear-CCMCache.ps1 -Clean -Days 14
```

## Notes

- The script requires administrative privileges to run.
- The script should be executed on the client machine where SCCM is installed.
- The default path for the CCMCache folder is `C:\Windows\ccmcache`.
- The script uses WMI to query and delete items from the CCMCache folder. Therefore, it may take some time to complete, depending on the size of the folder.
- The script is provided as-is and is not supported by Microsoft.

## Contributing

If you find a bug or want to suggest an improvement, feel free to open an issue or submit a pull request on GitHub.

## Acknowledgements

Special thanks to [@theruck242](https://github.com/theruck242) for identifying a critical issue and providing a robust solution to enhance the script's safety and reliability.
