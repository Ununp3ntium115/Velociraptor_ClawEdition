# Velociraptor_Setup_Scripts
Stand Alone Scripts for Velociraptor

 Deploy_Velociraptor_Standalone.ps1
    ▸ Downloads latest Velociraptor EXE (or re-uses an existing one)
    ▸ Creates C:\VelociraptorData as the GUI’s datastore
    ▸ Adds an inbound firewall rule for TCP 8889 (netsh fallback)
    ▸ Launches   velociraptor.exe gui --datastore C:\VelociraptorData
    ▸ Waits until the port is listening, then exits

    Logs → %ProgramData%\VelociraptorDeploy\standalone_deploy.log

 Deploy_Velociraptor_Server.ps1
    ▸ Binary + server.yaml →  C:\tools
    ▸ Datastore           →  C:\VelociraptorServerData
    ▸ Frontend / GUI      →  8000 / 8889 (HTTPS, self-signed)
    ▸ Two optional Y/N branches:  DNS  •  SSO (Google / Azure / GitHub / Okta / OIDC)
