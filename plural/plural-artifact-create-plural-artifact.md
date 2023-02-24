# Create Plural artifact

This way should be used if the artifact help plural and plural customers as well (a generic one).

## GitHub repo

Kubesoup has forked the [plural artifacts](https://github.com/pluralsh/plural-artifacts) here in the [KubeSoup/plural-artifacts](https://github.com/KubeSoup/plural-artifacts).

## Create plural artifact (example: "kyverno")

CAUTION: not all helm steps could be correct. Some could be missing or different. But it also depends on the helmchart itself.

- Prepare Git and folder:
```
git clone https://github.com/KubeSoup/plural-artifacts
cd plural-artifacts
git checkout -b feature/firstPluralArtifact
```
- Create artifact:
```
plural create
? Enter the name of your application:  kyverno
...
```
- Delete everything under: `plural-artifacts/kyverno/helm/kyverno/templates`
- Add `plural/icons/sparklogo.png`
- Add in `plural-artifacts/kyverno/helm/kyverno/Chart.yaml`
```
dependencies:
- name: kyverno
  version: "2.1.7" #maybe? v2.1.7
  repository: "https://kyverno.github.io/kyverno/"
```
- Download helm dependencies
```
cd kyverno
helm dependency update kyverno/helm/kyverno/
```

## Publish plural artifact

Ask David to publish it. If we would be able to do it by ourself, please update this doc accordingly.

## Use and deploy plural artifact

```
#Go into the repo from your cluster
cd at-onplural-sh

#First get official artifact
plural bundle install kyverno kyverno-aws
plural build --only kyverno

#If you want to develop and test, just link it to your local path
plural link helm kyverno --name kyverno --path /home/atxps/Git/KubeSoup/plural-artifacts/kyverno/helm/kyverno/
plural link terraform kyverno --name aws --path /home/atxps/Git/KubeSoup/plural-artifacts/kyverno/terraform/aws/

#Rebuild and then you can deploy
plural build --only kyverno 
plural deploy

kubectl get pods -n kyverno

#If you want to delete it from you cluster
#plural destroy kyverno
```