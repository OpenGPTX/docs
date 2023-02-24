
# Istio problems and solutions

## Scope

This documentation should be a summary of Istio problems and how potential solutions and workarounds can look like.
It should give a basic understanding about Istio including problems we faced so far and how we can deal with it.
In the past it turned out, we run into the same problems just with other applications. So let's share the experience.
Of course everything is very specific for the usecase in the end.

## Problem: Pod-to-pod communication is blocked by Istio by default

Istio blocks any pod-to-pod communication. There is no real fix for that. Only workarounds are possible.

There are different solutions/workarounds. Basically if you turn of Istio (on special ports) you also loose the Istio benefits like: network monitoring, tracebility, encryption, authentication, authorisation, ... and more. So it has an impact on the security.
The solutions described here are a kind of order. So start with solution 1 - it let istio enabled for everything. Only if that does not work, try Solution 2 and so on and so forth...

### Solution 1: Put a headless service in front of the application

This is the best solution to deal with Istio. In order to avoid pod-to-pod communication, just put a Kubernetes service infront of the pods. All the benefits from Istio are kept.

```
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: <svcname>
  namespace: <namespace>
spec:
  selector:
    notebook-name: sparkshowcase
  ports:
    - name: blockmanager
      protocol: TCP
      port: 7078
      targetPort: 7078
  type
```
Another option is to extend the existing service with additonal ports.

But sometimes it is not possible because of not unique enough labels (see `selector.notebook-name=sparkshowcase`) or the application really requires pod-to-pod communication.

### Solution 2: Turn off Istio for specific ports

If we know that no headless service is possible and only few needs to be opened, we can do that by adding the following annotation:
```
kubectl edit <statefulset|deployment|pod> <name> -n <namespace> 
metadata:
  annotations:
    traffic.sidecar.istio.io/excludeInboundPorts: "7078"
    traffic.sidecar.istio.io/excludeOuboundPorts: "7078"

#depending on the resource, the annotation needs to be added on another level
```

In case for multiple ports, the syntax looks like this:
```
    traffic.sidecar.istio.io/excludeInboundPorts: "7078,7079"
    traffic.sidecar.istio.io/excludeOuboundPorts: "7078,7079"
```

**Caution**: Adding the same annotation with different values passes validation but but doesn't work as expected (last one overwrites previous ones). Also wildcards aren't possible for ports.

Sometimes only `excludeInboundPorts` is required, sometimes only `excludeOutboundPorts`. It depends on the application/traffic. Please use the least possible solution.

### Solution 3: Turn off Istio for the application

Another possibility is to turn off Istio for the application. The result is that the Pod gets no istio sidecars injected anymore at all.

Just add the annotation `sidecar.istio.io/inject: "false"` accordingly:
```
kubectl edit <statefulset|deployment|pod> <name> -n <namespace> 
metadata:
  annotations:
    sidecar.istio.io/inject: "false"

#depending on the resource, the annotation needs to be added on another level
```

### Solution 4: Turn off Istio in the entire namespace

The last option is to turn off Istio in the entire namespace. As it turns off all the benefits/security from Istio in the entire namespaces, it should be the last option - only if other solutions are not possible:

```
kubectl label namespace <namespace> istio-injection=disabled
```

You can verifiy it by:
```
kubectl get namespace -L istio-injection
```
Or more deeply:
```
kubectl get namespace <namespace> -o yaml
metadata:
  labels:
    istio-injection: disabled
```

## Problem: Another init-container needs to start earlier than istio

In general Istio blocks the traffic until the envoy proxy is fully configured. If another init-container relies on needed traffic, it needs to start before Istio starts and blocks/configures everything.

### Solution: Change the startup order of the init-containers

The solution can be very specific for each application. In general the order of the init-containers need to be adjusted. More specifically in case of hashicorp vault: it provides an annotation in order to let another init-container start before Istio comes up:
```
  metadata:
    annotations:
      traffic.sidecar.istio.io/excludeOutboundPorts: "8200"
      vault.hashicorp.com/agent-init-first: "true"
      vault.hashicorp.com/agent-inject: "true"
```



## Problem: If Istio is not fully up and running - it blocks all the traffic - Pods can go into a terminating loop

### Solution: The main pod needs to start after istio is fully up and running

HOW? (no time spend on it yet)
