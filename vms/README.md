1. Show which operators are deployed
4. Show GitOps interface with virtual machines
2. Show Virtualization section with virtual machines deployed
   1. Deployed via application manifest in GitOps
5. Deploy the following changes by uncommenting:
   1. NetworkPolicy
   2. Autoscaling
6. Demonstrate GitOps sync changes
7. Show VM YAML (infrastructure-as-code)
8. Demonstrate Network Policy allowing traffic
9.  Demonstrate External secrets integration
   1. Show AWS secrets manager
   2. Show secrets store
   3. Show secret
   4. Open interface
10. Demonstrate logging integration
   1.  Open CloudWatch
   2.  Tail log group
   3.  `logger -p local0.info "This is a test log message"`
11. Demonstrate autoscaling event