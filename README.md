# docker-noip-client

Docker container based No-IP update client, based on Alpine linux and the official No-IP linux client.
This version requires the user to complete configuration by attaching an interactive terminal to the running container.

For an externally configurable alternative I strongly suggest using 
https://github.com/coppit/docker-no-ip instead.

This project wass intended as a personal learning exercise, as well as hopefully resulting in a slightly more secure implementation; 
I wasn't comfortable with using ENV or files to pass credentials, especially in scenarios where I might want to deploy remotely, and using Docker Secrets was slightly overkill for my use case.
