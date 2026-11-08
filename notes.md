az deployment sub What-if will error since one of the canary-vm params takes the value of a previously deployed subnetId which doesn't exist yet! Will work when actually created.

When specifying the sshpubkey parameter for creating a vm I need the contents of the ssh file, I do it like this so I don't have to copy the file contents and paste it manually into a command:
sshPubKey="$(cat ~/.ssh/azure_lab.pub)"

Full command example for deploying:
az deployment sub create --location uksouth --template-file infra/
main.bicep --parameters sshPubKey="$(cat ~/.ssh/azure_lab.pub)" adminUserName=

Going to have to scale back this project and remove the web server honeypot, cowrie set up is a bit more complex then i thought it would be and i'm worried about time before my free credit expires.

Connecting the log analytics workspace to Defender works automatically in azure portal but has to be done manually from the defender portal.