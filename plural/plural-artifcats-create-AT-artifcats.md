# Create AT artifact

This way should be used if the artifact is only for AT.

## GitHub repo

In contrast to forked/adjusted plural artifacts that are stored in [this repo](https://github.com/KubeSoup/plural-artifacts), our own AT artifacts are placed in [this repo](https://github.com/KubeSoup/at-artifacts). 

## Create AT artifact (example: "kyverno-spark")

Recompile Plural CLI - it needs to be at least the version from **24.03.2022**

- Prepare Git and folder:
```
git clone https://github.com/KubeSoup/at-artifacts.git
cd at-artifacts
git checkout -b feature/firstOwnArtifact
```
- Create artifact:
```
plural create
? Enter the name of your application:  kyverno-spark
? Enter the name of your publisher: Alexander Thamm
? Enter the category for your application: productivity (or something else)
? Will your application need a postgres database? (y/N) N
? Does your application need an ingress? (y/N) N
```
- explanation for previous prompt:
  - "publisher" needs to be `Alexander Thamm` (can be found [here](https://app.plural.sh/publishers/0446b57d-042c-4f42-904e-904f144c3a0a/repos))
  - if "postgres database" and/or "ingress" is true (y), then boiler-code is created

- Add `plural/icons/kyverno-spark.png`
- Be sure in `Pluralfile` `"Alexander Thamm"` is in quotes (Just to be sure. But it is already fixed in latest plural cli version.)
- Add `kyverno-spark/repository.yaml`

```
private: true
```

## Publish AT artifact

```
plural login
plural apply -f kyverno-spark/Pluralfile
```

You can find the AT artifacts under:
- https://app.plural.sh/publishers/
- https://app.plural.sh/publishers/0446b57d-042c-4f42-904e-904f144c3a0a
- https://app.plural.sh/repositories/6f196cda-a9ce-4d7a-9d9b-faf2bda1429a/bundles

## Use and deploy AT artifact

```
#Go into the repo from your cluster
cd at-onplural-sh

#First get previously published artifact
plural bundle install kyverno-spark kyverno-spark-aws
plural build --only kyverno-spark

#If you want to develop and test, just link it to your local path
plural link helm kyverno-spark --name kyverno-spark-helm --path /home/atxps/Git/KubeSoup/at-artifacts/kyverno-spark/helm/kyverno-spark/
plural link terraform kyverno-spark --name kyverno-spark-aws --path /home/atxps/Git/KubeSoup/at-artifacts/kyverno-spark/terraform/aws/

#Rebuild and then you can deploy
plural build --only kyverno-spark 
plural deploy

kubectl get pods -n kyverno-spark

#If you want to delete it from you cluster
#plural destroy kyverno-spark
```