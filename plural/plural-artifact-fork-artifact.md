# Fork artifact

## Scope

This manual shows how you can you can fork a Plural artifact.
It can be also used during developing and testing adjustments.

For more infos about logins, decryption and deployments - refer to other manuals.
## When to use it

The main purpose is to be able to make code adjustments in the Plural artifacts in order to increase the speed of prototyping. You can reference a local repo with your adjustments and after that you can deploy it on a cluster without plublishing the current working draft.

If the changes/improvements are really needed, we should talk to Plural in order to contribute to the upstream [Plural artifacts](https://github.com/pluralsh/plural-artifacts).

For the time being or if plural does not want to include the change into their upstream Plural artifact, it is okay to include it into our [forked repo](https://github.com/KubeSoup/plural-artifacts).


## GitHub repo(s)

- Plural artifact `kyverno` needs to be changed
- Your repo for your cluster is in: [at.onplural.sh.git](https://gitlab.alexanderthamm.com/kaas/at.onplural.sh.git) (your local path `/home/atxps/Git/at.onplural.sh`)
- For this specific example let's assume:
 Your forked changes go into: [plural-artifacts](https://github.com/KubeSoup/plural-artifacts) (your local path `/home/atxps/Git/KubeSoup/plural-artifacts`)

## Use local fork for deployments

```
cd /home/atxps/Git/at.onplural.sh

#If not installed and built yet, it is required to do so:
plural bundle install kyverno kyverno-aws
plural build --only kyverno

#Now you can link the artifact to your local repo (adjust paths)
plural link helm kyverno --name kyverno --path /home/atxps/Git/KubeSoup/plural-artifacts/kyverno/helm/kyverno/
plural link terraform kyverno --name aws --path /home/atxps/Git/KubeSoup/plural-artifacts/kyverno/terraform/aws/

#Rebuild is needed after any change
plural build --only kyverno

#Then you can deploy
plural deploy
```