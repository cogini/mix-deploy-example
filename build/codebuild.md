
# Run CodeBuild locally

https://aws.amazon.com/blogs/devops/announcing-local-build-support-for-aws-codebuild/
https://docs.aws.amazon.com/codebuild/latest/userguide/use-codebuild-agent.html

First, install Docker on your dev machine.

## Create custom Docker image with build deps:
```shell
cd build/docker

# Ubuntu
docker build -t mix-deploy-example/build/ubuntu:latest -f Dockerfile .

# CentOS
docker build -t mix-deploy-example/build/centos:latest -f Dockerfile.centos .
```

## Install CodeBuild agent

```shell
docker pull amazon/aws-codebuild-local:latest --disable-content-trust=false
```

## Build with CodeBuild

From project directory.

Our custom build image:
```shell
# Ubuntu
bin/build-codebuild-local -i mix-deploy-example/build/ubuntu -a ~/tmp/mix-deploy-example/output

# CentOS
bin/build-codebuild-local -i mix-deploy-example/build/centos -a ~/tmp/mix-deploy-example/output
```

Generic Ubuntu:
```shell
bin/build-codebuild-local -i ubuntu:bionic -a ~/tmp/mix-deploy-example/output
```

Generic CentOS:
```shell
bin/build-codebuild-local -i centos:7 -a ~/tmp/mix-deploy-example/output
```

Official AWS Python 2.7 image:
```shell
bin/build-codebuild-local -i aws/codebuild/python:2.7 -a ~/tmp/mix-deploy-example/output
```

## Notes

Building the AWS Docker image (not used):
```shell
git clone https://github.com/aws/aws-codebuild-docker-images.git
cd aws-codebuild-docker-images
cd ubuntu/unsupported_images/python/2.7.12
docker build -t aws/codebuild/python:2.7 .
```

### Postgres

https://wiki.postgresql.org/wiki/Apt
https://www.postgresql.org/about/news/1432/

http://initd.org/psycopg/docs/install.html
https://www.postgresql.org/download/linux/ubuntu/

