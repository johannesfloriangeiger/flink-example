# Build

```
mvn clean install
(cd terraform && terraform init)
```

# Install

```
(cd terraform && terraform apply)
```

Provide the name of the Bucket

# Demo

Create a file called `input.txt`, fill it with a few random lowercase words, upload it into the Bucket and start the KDA
application: Shortly afterward the folder `output` should appear in the Bucket with a file containing the uppercase
contents.

# Cleanup

```
(cd terraform && terraform destroy)
```