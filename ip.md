# MAC/IP Addresses and Server Names/Domains
---

Domains:
- development environment: `stefaanc.kluster.local`
- staging environment: `staging.kluster.local`
- production environment: `production.kluster.local`

MAC address structure: `00:00:02:{{segment}}:{{adapter}}:{{IP}}`
- segment: 
    - development on laptop: `00`
    - development on ESXi: `01`
    - staging on KVM: `10`
    - production on KVM: `11`
- adapter:
    - WAN: `00`
    - LAN: `01`
- IP:
    - hex-format of last part of IP-address



## HYPER-V

#### WAN (eth0)

MAC (static)        | IP (dhcp)         | FQDN
--------------------|-------------------|--------------------------
`00:00:02:00:00:10` | `X.X.X.16`        | `centos7-hyv.stefaanc.kluster.local`
`00:00:02:00:00:11` | `X.X.X.17`        | `gateway-hyv.stefaanc.kluster.local`

#### LAN (eth1)

MAC (static)        | IP (dhcp)         | FQDN
--------------------|-------------------|--------------------------
`00:00:02:00:01:01` | `192.168.100.1`   | `gateway-hyv.stefaanc.kluster.local`
`00:00:02:00:01:FE` | `192.168.100.254` | `{{hyper-v host}}`



## ESXi

#### WAN (ens160)

MAC (static)        | IP (dhcp)         | FQDN
--------------------|-------------------|--------------------------
`00:00:02:01:00:20` | `X.X.X.32`        | `centos7-vmw.stefaanc.kluster.local`
`00:00:02:01:00:21` | `X.X.X.33`        | `gateway-vmw.stefaanc.kluster.local`

#### LAN (ens192)

MAC (static)        | IP (dhcp)         | FQDN
--------------------|-------------------|--------------------------
`00:00:02:01:01:01` | `192.168.101.1`   | `gateway-vmw.stefaanc.kluster.local`



## KVM Staging

#### WAN (ens160)

MAC (static)        | IP (dhcp)         | FQDN
--------------------|-------------------|--------------------------
`00:00:02:10:00:30` | `X.X.X.48`        | `centos7.staging.kluster.local`
`00:00:02:10:00:31` | `X.X.X.49`        | `gateway.staging.kluster.local`

#### LAN (ens192)

MAC (static)        | IP (dhcp)         | FQDN
--------------------|-------------------|--------------------------
`00:00:02:10:01:01` | `192.168.150.1`   | `gateway.staging.kluster.local`



## KVM Production

#### WAN (ens160)

MAC (static)        | IP (dhcp)         | FQDN
--------------------|-------------------|--------------------------
`00:00:02:11:00:40` | `X.X.X.64`        | `centos7.production.kluster.local`
`00:00:02:11:00:41` | `X.X.X.65`        | `gateway.production.kluster.local`

#### LAN (ens192)

MAC (static)        | IP (dhcp)         | FQDN
--------------------|-------------------|--------------------------
`00:00:02:11:01:01` | `192.168.200.1`   | `gateway.production.kluster.local`

