NETENV_V := 1.0.0
TF_V := 0.6.3
OS_V := 1.0.5
OS_COMMIT := 96963b6

#export GOPATH := ${GOPATH}
BINPATH := ${GOPATH}/bin
export PATH := ${GOPATH}/bin:${PATH}
TF_URL := https://dl.bintray.com/mitchellh/terraform/terraform_${TF_V}_linux_amd64.zip
OS_URL := https://github.com/openshift/origin/releases/download/v${OS_V}/openshift-origin-v${OS_V}-${OS_COMMIT}-linux-amd64.tar.gz
NETENV_URL := https://github.com/kelseyhightower/setup-network-environment/releases/download/v${NETENV_V}/setup-network-environment


help:
	@cat Makefile

install:
	@mkdir -p .cache
	@go get -u github.com/dbohdan/remarshal
	@go get -u github.com/rakyll/boom
	@go install github.com/dbohdan/remarshal
	@go install github.com/rakyll/boom
	@curl -L -o .cache/setup-network-environment -z .cache/setup-network-environment ${NETENV_URL}
	@curl -L -o .cache/terraform.zip             -z .cache/terraform.zip             ${TF_URL}
	@curl -L -o .cache/openshift-origin.tar.gz   -z .cache/openshift-origin.tar.gz   ${OS_URL}
	@unzip -o   .cache/terraform.zip             -d ${BINPATH}/
	@tar -xf    .cache/openshift-origin.tar.gz   -C .cache/
	@ln -sf     .cache/openshift                    ${BINPATH}/openshift
	@ln -sf     ${BINPATH}/openshift                ${BINPATH}/oc
	@ln -sf     ${BINPATH}/openshift                ${BINPATH}/oadm

clean soft-clean:
	@rm -rf \
		terraform.* \
		.cache/*.{gz,zip,toml} \
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

up: clean compile
	@ssh-keygen -b 4096 -t rsa -f .cache/id -N ''
	@tar -czf .cache/pkg.tar.gz \
		openshift/ \
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

test:
	@./benchmark
