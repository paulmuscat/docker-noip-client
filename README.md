# docker-noip-client

Docker container based No-IP dynamic DNS update client, based on Alpine linux (https://wiki.alpinelinux.org) and the official No-IP linux dynamic update client (https://www.noip.com/download?page=linux).

This version requires the user to complete configuration by attaching an interactive terminal to the running container.
The client will ask for username, password, target group/domain and polling frequency. 
The client only updates when the stored IP address from the prior update doesn't match the IP presented by ip1.dynupdate.no-ip.com. 
Subsequently the container can be committed and/or stopped and restarted as needed.
The client logs a message to docker logs when it performs an update.

For an externally configurable alternative I strongly suggest using 
https://github.com/coppit/docker-no-ip instead.

This project was intended as a personal learning exercise, as well as hopefully resulting in a slightly more secure implementation; 
I wasn't comfortable with using run parameters, ENV values or plaintext files to pass or store credentials, especially when I might want to deploy remotely. 
Using Docker Secrets was slightly overkill for my use case, especially as I wasn't planning to always use swarm.

A nice summary of the ENV issue here: https://diogomonica.com/2017/03/27/why-you-shouldnt-use-env-variables-for-secret-data/

Alpine results in extremely small images so once manually configured the container can be easily redeployed.
