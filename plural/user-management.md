# User Management

### Grant user to Kubeflow dashboard

#### Prerequisites

- You need enough permissions to impersonate the according service account (a.k.a deployment user)
- Knowing what's the correct service account for the according kubeflow cluster (keepass can help)
  - In this example it is `dev.at.onplural.sh@alexanderthamm.com` for the cluster `dev.at.onplural.sh`

#### Start with impersonation

- Login on https://app.plural.sh/ with your personal account
- In the left bar: click on "Account"
- Click on "Service Accounts"
- Look for the according service account (e.g. `dev.at.onplural.sh@alexanderthamm.com`)
- Click on the button "impersonate"

![impersonation](/img/plural/impersonation.png)

#### Grant user in Kubeflow artifact

- Be sure you are correctly impersonated
- In the left bar: click on "Explore"
- Then a little below: click on "Installed"
- In the list: click on "kubeflow"
- Click on "Configure"
- Click on "OpenID Connect"
- In "2. Attach users and groups": search for the according user you want to grant
- In the upper right corner: click on "Update"
- Perhaps the user needs to relogin / clearing browser cache

![grant user](/img/plural/grant-user.png)
