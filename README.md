# DigitalOcean Demo App

It can be difficult to get acquainted with a new cloud services platform. We find that the easiest way to get up and running is to deploy an application!

This repository contains a demo application and automation to launch it on your own DigitalOcean account. This will allow you to get a feel for what it's like to run code on DigitalOcean.

## What's Involved?

### The Application

The actual application we'll be deploying is a "status page". A status page is a web page that shows status information for another product or service. For example, if you want to check on the status of DigitalOcean, you could go to our status page: https://status.digitalocean.com/.

The status page we're deploying isn't quite as full-featured, but perhaps it could be someday :P

The application code can be found in the [app](./app/) directory. It's written in [Go](https://golang.org/) and uses [MySQL](https://www.mysql.com/) as its database.

### Infrastructure as Code (IaC)

This is the code that defines our DigitalOcean cloud resources! In this project, we've defined our infrastructure using [Terraform](https://www.terraform.io/). Terraform has a great [provider for DigitalOcean](https://www.terraform.io/docs/providers/do/index.html). The Terraform configuration can be found in the [terraform](./terraform/) directory. In [main.tf](./terraform/main.tf), you'll find all resources involved in running our status page application.

### Automated Provisioning

Provisioning is the process of bringing infrastructure components to a desired state - which in our case involves installing software and running services on DigitalOcean [Droplets](https://www.digitalocean.com/products/droplets/). We need to provision a database server with MySQL and web servers with our status page application. We're using [Ansible](https://www.ansible.com/) for automating the necessary provisioning. The database server and web servers require different instructions to be provisioned appropriately. Ansible organizes sets of instructions as "playbooks". Our Ansible code can be found in the [ansible](./ansible/) directory.

### Tying It All Together

Everything is tied together by a launch script ([statuspage-launch.sh](./statuspage-launch.sh)). This runs our IaC and provisioning code in the necessary order. The next section explains how to run it!

## Run the Application!

Now that you have an understanding of the technology that will come into play, let's run the application!

We're going to do this by creating a single Droplet with the DigitalOcean control panel. This Droplet is going to be our [bastion host](https://en.wikipedia.org/wiki/Bastion_host). This type of host is traditionally referenced in infrastructure designs as a means for implementing security measures. A similar term for such a host is "[jump server](https://en.wikipedia.org/wiki/Jump_server)". In our case, we're using it as an SSH gateway and also the coordinating system for building out the rest of our infrastructure.

Before we create this Droplet, we need to create a DigitalOcean "personal access token" and "spaces access keys". This can be done from the "API" tab of the DigitalOcean Control Panel.

![DigitalOcean Control Panel API Tab](./images/README.ss-api.png)

Go ahead and create one of each. Take note of the token/keys - we'll need these later.

_**Note:** the personal access token will be a single token. The spaces access key will have two parts - a key and a secret key._

Now we're ready to create our bastion Droplet. Go to the "Droplets" tab on the DigitalOcean control panel.

![DigitalOcean Control Panel Droplets Tab](./images/README.ss-droplets.png)

* Click "Create Droplet".

* Under "Choose an image", ensure that "Ubuntu" is selected.

* Under "Choose a size", select the cheapest option.

* Ignore "Add block storage" - we do not need block storage for the bastion host.

* Under "Choose a datacenter region", select the "3" on "New York".

* Under "Select additional options", select the checkboxes for "Private networking" and "User data".

* When you select "User data", a text field will appear. Paste the following code into this text field and update the lines starting with `export` with your personal access token and spaces keys:

```
#!/bin/bash

export do_token="PUT YOUR PERSONAL ACCESS TOKEN HERE"
export do_spaces_id="PUT YOUR SPACES ACCESS KEY HERE"
export do_spaces_key="PUT YOUR SPACES ACCESS SECRET HERE"
export version="0.0.1"

curl https://raw.githubusercontent.com/do-community/demo-app/v$version/statuspage-launch.sh | bash
```

_**Note:** we do not recommend piping scripts from the internet to `bash` as a common practice. This is to keep the copy/paste content at a minimum so we can focus on getting our application up._

* Under "Add your SSH keys", select an existing SSH key or click the "New SSH Key" button and enter a public key. This should be a public SSH key of your own. You will need this in order to connect to the bastion host.

* Under "Finalize and create" and "Choose a hostname", give your Droplet a more appropriate name - "bastion" would be a pretty good one.

* Click "Create".

That's about it! Your DigitalOcean infrastructure is now being created!

Once, your Droplet is up, you should be able to SSH to it and monitor the launch progress. This can be done with:

```
ssh root@<bastion-ip>

tail -f /var/log/cloud-init-output.log
```

After a few minutes, the launch process will have completed.

When it does, open your load balancer IP address in a browser and to see your status page!

## The DigitalOcean Control Panel

Now that we have our status page running, we can explore the Control Panel!

The DigitalOcean resources we've just created include:

* [Droplets](https://cloud.digitalocean.com/droplets)
* [Spaces](https://cloud.digitalocean.com/spaces)
* [Load Balancers](https://cloud.digitalocean.com/networking/load_balancers)
* [Firewalls](https://cloud.digitalocean.com/networking/firewalls)

First thing to check out is the dashboard tab:

![DigitalOcean Control Panel Dashboard Tab](./images/README.ss-dashboard.png)

Here we get a high level view of the DigitalOcean resources we've created.

If we click one of our Droplets, it will take us to its Graphs view for the Droplet you selected:

![DigitalOcean Control Panel Droplet](./images/README.ss-droplet.png)

Because we've enabled monitoring on our Droplets, we get some really great graphs right on the control panel. You'll probably the system metrics are a bit more volatile than you'd expect for infrastructure running an application that's no one's actually using. This is because we've added a job to the bastion server's crontab to send requests to your load balancer. Check the `/etc/crontab` file on your bastion server so see exactly what it's doing.

In addition to graphs, having monitoring enabled allows us to create alerting policies to receive notifications when system metrics cross thresholds of our choosing. Alerting policies can be set up on the [Monitoring tab](https://cloud.digitalocean.com/monitors) of the Control Panel.

Be sure to also explore your newly created [space](https://cloud.digitalocean.com/spaces), [load balancer](https://cloud.digitalocean.com/networking/load_balancers), and [firewalls](https://cloud.digitalocean.com/networking/firewalls)!

## Destroy the Application

While it's really cool that you have a running application on your DigitalOcean account, you should probably tear it down. Though the resources it uses are relatively inexpensive, it _does_ actually cost money!

When we launched the application, we copied a cleanup script onto the bastion server - [statuspage-destroy.sh](./statuspage-destroy.sh). If you look at the script, you'll see that the destruction is coordinated with Terraform. Terraform knows of all resources it originally created through its state file - which we've stored in DigitalOcean Spaces. It will not affect any other resourses associated with your account.

When you're ready to destroy your status page application, you must connect to your bastion server and execute the script:

```
ssh root@<bastion-ip>

./statuspage-demo/statuspage-destroy.sh
```

All that will be left at this point is the bastion server itself. To destroy the bastion server,

* Navigate to the "Droplets" tab on the DigitalOcean control panel.

* Click "More" on the right side of the Droplet to expose its dropdown menu.

* Click "Destroy" at the bottom of the menu.

* Under "Destroy droplet", click the "Destroy" button.

* Click "Confirm".

That's it! Our beloved status page is completely destroyed and we're back to where we started. But at least you know what you're doing now! You're ready to deploy your own application on DigitalOcean :sunglasses:

## Troubleshooting

The first thing to do is check the cloud-init log on your bastion host. You can run the following to output the last 100 lines:

```
ssh root@<bastion-ip>

tail -100 /var/log/cloud-init-output.log
```

### API Keys and Tokens

It's common that personal access tokens or spaces access keys are set incorrectly.

#### Spaces Access Keys

If your spaces access keys are incorrectly, you'll see sommething like the following towards the end of your `cloud-init-output.log`:

```
...

botocore.exceptions.ClientError: An error occurred (InvalidAccessKeyId) when calling the ListBuckets operation: Unknown

...

Error loading state: InvalidAccessKeyId:
        status code: 403, request id: tx0000000000000000436da-005ac64745-176e91-nyc3a, host id:

...
```

This indicates that your spaces access key ID was entered incorrectly.

The following would indicate that your spaces access key secret was entered incorrectly:

```
...

botocore.exceptions.ClientError: An error occurred (SignatureDoesNotMatch) when calling the ListBuckets operation: Unknown

...

Error loading state: SignatureDoesNotMatch:
        status code: 403, request id: tx000000000000000008935-005ac64db9-171d53-nyc3a, host id:

...
```

If either occur, start over by deleting your bastion droplet and create a new one with valid key values in its "User Data" script.

#### Personal Access Tokens

If your personal access token was entered incorrectly, you'll see output like the following:

```
...

Error: digitalocean_droplet.bastion (import id: 88489983): 1 error(s) occurred:

* import digitalocean_droplet.bastion result: 88489983: digitalocean_droplet.bastion: Error retrieving droplet: GET https://api.digitalocean.com/v2/droplets/88489983: 401 Unable to authenticate you.

...
```

Again, the easiest approach would be to start over by deleting your bastion droplet and create a new one with a valid token in its "User Data" script.

A less easy approach, if you feel like getting your hands dirty, is to update your token in `/root/statuspage-demo/terraform/token.auto.tfvars`. And then attempt to re-apply your Terraform configuration with `cd /root/statuspage-demo/terraform/ && terraform apply -auto-approve`.

### Terraform Apply Failure

Another common issue is that our `terraform apply` command failed for some reason or another. If this is the case, you'll see the following accompanied by a list of errors:

```
...

Error: Error applying plan:

...
```

In cloud computing and software in general, there's an  _endless_ list of problems that can arise. Because we're depending on so many different services from DNS to DigitalOcean APIs, there's a good chance that one of them didn't behave in the way we needed it to. Terraform does a good job with error messages so you should be able to tell what failed in your cloud-init output.

Whatever it is that failed, there's a good chance it will succeed if you re-apply your Terraform configuration. You can do this with the following command:

```
cd /root/statuspage-demo/terraform/ && terraform apply -auto-approve
```

### ANYTHING ELSE!!!

First off, sorry for the frustration! Debugging infrastructure code can be a pain. But to look at the bright side, debugging/troubleshooting in general can also be a great learning experience! Our best advice at this point is to recreate your bastion droplet. At least it's a pretty easy thing to do - just a few clicks on the ol' DigitalOcean Control Panel!
