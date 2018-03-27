# digital-ocean-demo-app

1) Go to `API` tab and create Personal and Spaces access tokens/keys
    We will need them later.
2) Go to `Droplets` tab and create new droplet(aka VM) 
    That's will be our jumphost(aka bastion) to access/manipulate our infrastructure
    2a) OS: ubuntu
    2b) Check `private network` and `user data` checkboxes
    2c) Copy-Paste from user_data file to `user data` input field
    2d) Edit Personal and Spaces access tokens/keys
    2e) Name your new droplet as "bastion"
    2f) Launch your Droplet
3) To monitor how Demo infrastructure creating process is going on. Login to our bastion droplet and enter following command:
```bash
tail -f /var/log/cloud-init-output.log
```