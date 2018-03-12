# digital-ocean-demo-app

1) Go to 'API tab' and create Personal and Spaces access tokens/keys
    We will need them later.
2) Go to 'Droplets tab' and create new droplet(aka VM) 
    That's will be our jumphost(aka bastion) to access/manipulate our infrastructure
    2a) OS: ubuntu
    2b) Userdata: copy from user_data file
    2c) Edit Personal and Spaces access tokens/keys
    2d) Name your new droplet as "bastion"