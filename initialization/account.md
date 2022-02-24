# How to get an account and namespace

1.  Contact the platform team (for now: <nico.becker@alexanderthamm.com>) and provide your email address

2.  You will receive an invitation link. Clicking on it will lead you to the
    registration page. The email field is prefilled. Please provide your name
    and click on **continue**.

    ![registration name](/img/initialization/accept-invite.png)

3.  Next, you have to set a password. Click on **Sign up**. Make sure you note
    down your login credentials (email, password). Those will be required later
    when you want to login to the ML Platform!

    ![registration password](/img/initialization/set-password.png)

3.  You should now see the plural dashboard. This page is not important for any
    aspect of your work on the platform. You can log out and safely ignore it. 

    ![plural dashboard](/img/initialization/plural-logged-in.png)

4.  After your sign up, you will receive an email from plural with a 
    confirmation link (also check spam). Click the link. You might have to log
    in again with your credentials from from the registration.

5.  go to https://kubeflow.at.onplural.sh and log in with your credentials. 

    ![namespace view](/img/initialization/login.png)

6.  The ML Platform wants to access your plural profile. Click **Allow**.

    If you get a `403` error here, please contact 
    <nico.becker@alexanderthamm.com>. This probably means you have not been
    added to the platform user group yet. In general, you will be added to that
    user group on the day of your onboarding. 

    ![namespace view](/img/initialization/allow-access.png)

7.  You should be redirected to the setup page. Click on **Start Setup**

    ![create namespace view](/img/initialization/welcome.png)

8.  Accept the proposed name or enter a new name for your namespace and click
    on **Finish**

9.  You should now see the Kubeflow Dashboard. You are ready to rumble!

    ![namespace view](/img/initialization/kubeflow-dashboard.png). 

## Next steps

-   For an overview of the available components, continue reading [here](../initialization/components.md)
-   To learn how to launch notebook servers, continue [here](../notebooks/configuration.md)
