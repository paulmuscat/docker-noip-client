# docker-noip-client

Docker container based No-IP DNS update client, based on Alpine linux (https://wiki.alpinelinux.org) and the official No-IP linux dynamic update client (https://www.noip.com/download?page=linux).
This version requires the user to complete configuration by attaching an interactive terminal to the running container.
Subsequently the container can be stopped and restarted as needed.

For an externally configurable alternative I strongly suggest using 
https://github.com/coppit/docker-no-ip instead.

This project was intended as a personal learning exercise, as well as hopefully resulting in a slightly more secure implementation; 
I wasn't comfortable with using run parameters, ENV values or plaintext files to pass or store credentials, especiallys when I might want to deploy remotely, and using Docker Secrets was slightly overkill for my use case.
Alpine results in extremely small images so once manually configured the container can be easily redeployed.
