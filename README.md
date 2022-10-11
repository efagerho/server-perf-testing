# Server Performance Testing

Creates two EC2 instances in the same cluster placement group. Both servers have
perf and bpftrace installed as well as compilers for Java, Rust and Go.

Usage:

1. Update variables.tf to contain your SSH public key and the AWS profile name.
2. Run terraform apply.
