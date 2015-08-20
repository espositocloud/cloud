NETENV_V := 1.0.0
TF_V := 0.6.3
OS_V := 1.0.4
OS_COMMIT := 757efd9
HEKA_V := 0.10.0b1
HEKA__V := 0_10_0b1

#export GOPATH := ${GOPATH}
BINPATH := ${GOPATH}/bin
export PATH := ${GOPATH}/bin:${PATH}
TF_URL := https://dl.bintray.com/mitchellh/terraform/terraform_${TF_V}_linux_amd64.zip
OS_URL := https://github.com/openshift/origin/releases/download/v${OS_V}/openshift-origin-v${OS_V}-${OS_COMMIT}-linux-amd64.tar.gz
HEKA_URL := https://github.com/mozilla-services/heka/releases/download/v${HEKA_V}/heka-${HEKA__V}-linux-amd64.tar.gz
NETENV_URL := https://github.com/kelseyhightower/setup-network-environment/releases/download/v${NETENV_V}/setup-network-environment


help:
	@cat Makefile

install:
	@go install github.com/dbohdan/remarshal
	@curl -L -o .cache/setup-network-environment -z .cache/setup-network-environment ${NETENV_URL}
	@curl -L -o .cache/terraform.zip             -z .cache/terraform.zip             ${TF_URL}
	@curl -L -o .cache/openshift-origin.tar.gz   -z .cache/openshift-origin.tar.gz   ${OS_URL}
	@curl -L -o .cache/heka.tar.gz               -z .cache/heka.tar.gz               ${HEKA_URL}
	@unzip -o   .cache/terraform.zip             -d ${BINPATH}/
	@tar -xf    .cache/openshift-origin.tar.gz   -C .cache/
	@tar -xf    .cache/heka.tar.gz               -C .cache/  --strip-components 1
	@ln -sf     .cache/openshift                    ${BINPATH}/openshift
	@ln -sf     ${BINPATH}/openshift                ${BINPATH}/oc
	@ln -sf     ${BINPATH}/openshift                ${BINPATH}/oadm

clean soft-clean:
	@rm -rf \
		terraform.* \
		openshift/*.toml \
		.cache/*.{gz,zip} \
		.cache/master/ \
		.cache/id*

full-clean: clean
	@rm -rf \
		${BINPATH}/terraform* \
		.cache/

compile:
	@mkdir -p .cache
	@remarshal \
		-if yaml -i terraform/digitalocean.yaml \
		-of json -o terraform.tf.json
	@remarshal \
		-if yaml -i vars.yaml \
		-of json -o terraform.tfvars
	@remarshal \
		-if yaml -i openshift/heka.yaml \
		-of toml -o openshift/heka.toml

up: clean compile
	@ssh-keygen -b 4096 -t rsa -f .cache/id -N ''
	@tar -czf .cache/master.tar.gz \
		openshift/ \
		.cache/{setup-network-environment,openshift,bin,lib,share}
	@tar -czf .cache/node.tar.gz \
		.cache/{setup-network-environment,openshift}
	@terraform plan -out terraform.tfplan
	@terraform apply terraform.tfplan

delete destroy: compile
	@terraform plan -destroy
	@terraform destroy

# Others
# https://terraform.io/docs/commands/graph.html
infrastructure-graph:
	@terraform graph | dot -Tsvg > graph.svg
