# Stord Coding Exercise

For this project I decided to use [kind](https://kind.sigs.k8s.io/) for a local k8s cluster, and [Postgres Operator](https://github.com/zalando/postgres-operator).
It has been a few years now since I have had to work with k8s regularly, and these were some of the tools I was using at that time. 

I have consumed helm charts, but this was the first time I have ever had to create one. In my previous k8s clusters, all the internal (non 3rd party) apps were generally deployed with standard k8s manifests, so helm is a bit new in that regard. I skimmed the Helm docs and more or less used the quick start guide to create a very basic chart.  

There is no doubt in my mind there is a lot of room for improvment on this little project. Given more time and exposure with Helm, I am sure I would find a good workflow with it.  

I included a `runtime.exs` as a configMap, I needed to enable the SSL on the database connection. Other areas I would generally address would be to use more scoped postgres user roles, k8s security, ACLS, namespaces and resource allocations. Since this is a just a locally running setup, I did provision two worker nodes, but only 1 is providing ingress. I am also certain there are more effective ways to consume existing secrets from k8s using templating. I am sure the app or configuration could be modified to load credentials in a far more secure manner than in this example.


## Pre-Requisites

Assuming macOS, the following pre-requistes are required

```shell
brew install helm kind kubectl
```

## Running

I have droped in a quick and dirty shell script to provision the k8s cluster, the postgress operator and database cluster, and finally the Phoenix application provided.

```shell
./create.sh
```

Once this script has been execute, the application should be available on (http://localhost/todos). 

## Connecting to Postgres

I found it was easiest to run the portfoward in a simple loop in one terminal.

```shell
while :; do kubectl port-forward $(kubectl get pod -l cluster-name=challenge-database,spilo-role=master -o jsonpath='{.items[0].metadata.name}') 15432:5432;done
```

And then connect in a different terminal as the connection likes to close.
```shell
export PGSSLMODE=require
export PGPASSWORD=$(kubectl get secret stord.challenge-database.credentials.postgresql.acid.zalan.do -o 'jsonpath={.data.password}' | base64 -d)
psql -h localhost -U stord -p 15432 -d stord_prod
```

## Teardown

to destroy the cluster simply run:
```shell
./destroy.sh
```



