## Configure ESXi Server

#### Enable ESXi Shell and SSH services on the ESXi Server

1. browse to the ESXi management console, ignoring the `Not Secure` warning - we will solve this later 

2. start the `TSM` and `TSM-SSH` services 


#### Install the GuestIPHack on the ESXi server (for packer's vmware builders)

1. use putty or some other tool to open a terminal into the ESXi server

2. execute `esxcli system settings advanced set -o /Net/GuestIPHack -i 1`


#### Install a vSphere Installation Bundle (VIB) for a VNC on the ESXi server (for packer's vmware builders) 

1. use putty or some other tool to open a terminal into the ESXi server

2. upload `$ROOT/downloads/abiquo-vnc.vib` in a ESXi datastore (for instance `datastore1`) using the ESXi management console, or using winSCP or some other tool

3. enter maintenance mode using the ESXi management console,
   or by executing `esxcli system maintentanceMode set --enable true`

4. set `Community` acceptance level using the ESXi management console,
   or by executing `esxcli software acceptance set --level=CommunitySupported`

5. execute `esxcli software vib install -v /vmfs/volumes/datastore1/abiquo-vnc.vib -f`

6. exit maintenance mode using the ESXi management console, 
   or by executing `esxcli system maintentanceMode set --enable false`

7. reboot the ESXi server using the ESXi management console,
   or by executing `shutdown -r now`

8. verify that the `Abiquo-VNC` firewall rules are set using the ESXi management console,
   or by executing `esxcli network firewall ruleset list`


#### Install HTTPS certificates on the ESXi server

1. open a PowerShell terminal

2. execute `Generate-ServerCertificatesESXi.ps1 $IP_ADDRESS $SERVER_NAME $IP_DOMAIN`,
   for instance

   ```powershell
   Generate-ServerCertificatesESXi.ps1 "192.168.0.3" "esxiserver" "kluster.local"
   ```

  - the script will silently import an intermediate-CA certificate for the ESXi server.
  - the generated certificates can be found in `$ROOT\.pki\esxiserver.kluster.local` 
  <br/>

3. use putty or some other tool to open a terminal into the ESXi server

4. enter maintenance mode using the ESXi management console,
   or by executing `esxcli system maintentanceMode set --enable true`

5. rename the old `rui.key` and `rui.crt` in the `/etc/vmware/ssl/` folder on the ESXi server, using winSCP or some other tool

6. upload the newly generated `rui.key` and `rui.crt` to the `/etc/vmware/ssl/` folder on the ESXi server, using winSCP or some other tool

7. exit maintenance mode using the ESXi management console,
   or by executing `esxcli system maintentanceMode set --enable false`

8. reboot the ESXi server using the ESXi management console,
   or by executing `shutdown -r now`

9. verify that you don't get a `Not Secure` warning when browsing to the ESXi management console
