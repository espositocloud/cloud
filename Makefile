NETENV_V := 1.0.0
TF_V := 0.6.3
OS_V := 1.0.4
OS_COMMIT := 757efd9
HEKA_V := 0.10.0b1
HEKA__V := 0_10_0b1

#export GOPATH := ${GOPATH}
CACHE := `pwd`/.cache
BINPATH := ${GOPATH}/bin
export PATH := ${GOPATH}/bin:${PATH}
TF_URL := https://dl.bintray.com/mitchellh/terraform/terraform_${TF_V}_linux_amd64.zip
OS_URL := https://github.com/openshift/origin/releases/download/v${OS_V}/openshift-origin-v${OS_V}-${OS_COMMIT}-linux-amd64.tar.gz
HEKA_URL := https://github.com/mozilla-services/heka/releases/download/v${HEKA_V}/heka-${HEKA__V}-linux-amd64.tar.gz
NETENV_URL := https://github.com/kelseyhightower/setup-network-environment/releases/download/v${NETENV_V}/setup-network-environment


up: clean compile build
	@terraform plan -out terraform.tfplan
	@terraform apply terraform.tfplan

delete destroy: compile
	@terraform plan -destroy
	@terraform destroy

clean soft-clean:
	@rm -rf \
		terraform.* \
		openshift/*.toml \
		${CACHE}/master.tar.gz \
		${CACHE}/node.tar.gz \
		${CACHE}/master/ \
		${CACHE}/id*

full-clean: clean
	@rm -rf \
		${BINPATH}/terraform* \
		.cache

compile:
	@mkdir -p ${CACHE}
	@remarshal \
		-if yaml -i terraform/digitalocean.yaml \
		-of json -o terraform.tf.json
	@remarshal \
		-if yaml -i vars.yaml \
		-of json -o terraform.tfvars
	@remarshal \
		-if yaml -i openshift/heka.yaml \
		-of toml -o openshift/heka.toml

build:
	@ssh-keygen -b 4096 -t rsa -f ${CACHE}/id -N ''
	@cd ${CACHE} && tar -czf master.tar.gz \
		setup-network-environment \
		openshift \
		heka-${HEKA__V}-linux-amd64 \
		../openshift
	@cd ${CACHE} && tar -czf node.tar.gz \
		setup-network-environment \
		openshift
	@echo 'Builds done'

# Prerequisites
install:
	@go install github.com/dbohdan/remarshal
	@curl -L -o ${CACHE}/setup-network-environment -z ${CACHE}/setup-network-environment ${NETENV_URL}
	@curl -L -o ${CACHE}/terraform.zip             -z ${CACHE}/terraform.zip             ${TF_URL}
	@curl -L -o ${CACHE}/openshift.tar.gz          -z ${CACHE}/openshift.tar.gz          ${OS_URL}
	@curl -L -o ${CACHE}/heka.tar.gz               -z ${CACHE}/heka.tar.gz               ${HEKA_URL}
	@unzip -o   ${CACHE}/terraform.zip    -d ${BINPATH}/
	@tar -xf    ${CACHE}/openshift.tar.gz -C ${CACHE}/
	@tar -xf    ${CACHE}/heka.tar.gz      -C ${CACHE}/
	@ln -sf     ${CACHE}/openshift           ${BINPATH}/openshift
	@ln -sf     ${CACHE}/openshift           ${BINPATH}/oc
	@ln -sf     ${CACHE}/openshift           ${BINPATH}/oadm

# Others
# https://terraform.io/docs/commands/graph.html
infrastructure-graph:
	@terraform graph | dot -Tsvg > graph.svg
