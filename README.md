# Secure Boot Certificate Check
PowerShell script to check if [Microsoft Secure Boot certificates](https://support.microsoft.com/en-us/topic/windows-secure-boot-certificate-expiration-and-ca-updates-7ff40d33-95dc-4c3c-8725-a9b95457578e) are updated. The script can be executed locally or remotely.

## Usage

**Run the following command after launching PowerShell as administrator**
`powershell.exe -ExecutionPolicy Bypass -File .\check.ps1`

## Arguments
- `-Minimal` (optional) run a slimmed down version of the script
- `-LogFile` (optional) specify a directory & file to log script output