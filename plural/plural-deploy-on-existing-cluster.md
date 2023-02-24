# Deploy on an existing Plural cluster

This is an example for KF6 where the Plural cluster is called "at.onplural.sh". Adjust it as you want for other AWS accounts and cluster names.
## Overview

Limitation: One (technical) user can only deploy one Plural cluster (at least when they should have different artifacts).
In order to be able to deploy on existing cluster by everyone in our team, we need to use one seperated technical user per Plural cluster. 

Here is an overview about the steps for this manual:
- Login in with Plural cli with the correct technical user
- Login into AWS cli via exporting environmental variables
- Clone repo and decrypt files
- Deploy on an existing Plural cluster
- Push your changed into the repo

## Logins

### Login in with Plural cli with the correct technical user

Here you can find the [keepass repo](https://github.com/KubeSoup/secrets).

```
plural login #(use correct technical user for the Plural cluster. e.g. deployment.kubesoup@alexanderthamm.com - password is in keepass)
```

### Login into AWS cli via exporting environmental variables

Open https://alexanderthamm.awsapps.com/start#/ and click on "Command line or programmatic access" for the according cluster (e.g. kf6)
```
export AWS_ACCESS_KEY_ID="ASIA3*********ICNNPY"
export AWS_SECRET_ACCESS_KEY="3fz5I*********HyFJYAao8y9O2"
export AWS_SESSION_TOKEN="IQoJb3JpZ2luX2VjEHoaDGV1LWNlbnRyYWwtMSJHMEUCIC113GLxuUreCi8/eoYNJkrhrIPbEtHcKAvQ7gPs9IC6AiEAr5MhLgBqBsMJ6puYusyeITRxKys0qsyXIisbe8uUyJMqrQMIo///////////ARAAGgw3NzY2MDQ5MTI0NDciDMI7//Hw4Uo/ZRw3IyqBA2Gw73wLaJ8PVtThAW4rx9cBm0g286NHQrCMpfjLqXSEUsD1MuLYqROe4spmqkwaTDdMDxK1svqrEAEErtkAjJCzln0KwlTyxhPA884WO3nrwQYw4VvdXmr9GkaaoMzgwJFLMc7j*****************xQIB5bxDvECskmQiKONWXhBW6SRNjZgDH0HOK6O2qxWrQVE3palnBb3tT5XDws/0wXuucOUFNK9du50s2s9+lm/XEDmJKrNg3"
```

## Clone repo and decrypt files

Clone the correct repository from the Plural cluster, you want to deploy on.
```
git clone https://gitlab.alexanderthamm.com/kaas/at.onplural.sh.git
cd at.onplural.sh
```

Clean up old keys and set up correct key (the key is unique for every technical user so that it is also unique for every Plural cluster):
```
rm ~/.plural/config.yml
rm ~/.plural/identity
rm ~/.plural/key
vi ~/.plural/key
key: Vm3CscU***********J5DA3hIx8qk=       #password can be found in keepass e.g. "at.onplural.sh plural service account" as an attached file
```

Now decrypt files within the repository:
```
cat context.yaml       #is ENcrypted
plural crypto init
plural crypto unlock
cat context.yaml       #is DEcrypted
```

## Deploy on an existing Plural cluster

The following example installs kyverno as an additional artifact on the Plural cluster:
```
plural bundle install kyverno kyverno-aws
plural build --only kyverno

plural deploy
```

## Workflow

1. Install/change artifacts
2. Build
3. Deploy
4. Test
5. Go to step 1 if there are issues
6. Push to master/main
