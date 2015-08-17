TERRAFORM_VERSION := 0.6.3
OPENSHIFT_VERSION := 1.0.4-757efd9

#export GOPATH := ${GOPATH}
CACHE := .cache
BINPATH := ${GOPATH}/bin
export PATH := ${GOPATH}/bin:${PATH}
TERRAFORM_URL := https://dl.bintray.com/mitchellh/terraform/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
OPENSHIFT_URL := https://github.com/openshift/origin/releases/download/v1.0.4/openshift-origin-v${OPENSHIFT_VERSION}-linux-amd64.tar.gz
SETUP_NET_ENV_URL := https://github.com/kelseyhightower/setup-network-environment/releases/download/v1.0.0/setup-network-environment


up: clean compile build
	@terraform plan -out terraform.tfplan
	@terraform apply terraform.tfplan

delete destroy: compile
	@terraform plan -destroy
	@terraform destroy

compile:
	@mkdir -p ${CACHE}
	@remarshal \
		-if yaml -i platform/digitalocean.yaml \
		-of json -o terraform.tf.json
	@remarshal \
		-if yaml -i vars.yaml \
		-of json -o terraform.tfvars

c clean soft-clean:
	@rm -rf \
		terraform* \
		${CACHE}/{master,node}.tar.gz \
		${CACHE}/master/ \
		${CACHE}/id_*

full-clean: clean
	@rm -rf \
		${BINPATH}/terraform* \
		.cache

build:
	@ssh-keygen -b 4096 -t rsa -f ${CACHE}/id_rsa -N ''
	@cd ${CACHE} && tar -czf master.tar.gz \
		setup-network-environment \
		openshift
	@cd ${CACHE} && tar -czf node.tar.gz \
		setup-network-environment \
		openshift
	@echo 'Builds done'

# Prerequisites
install:
	@go install github.com/dbohdan/remarshal
	@curl -L -o ${CACHE}/terraform.zip             -z ${CACHE}/terraform.zip             ${TERRAFORM_URL}
	@curl -L -o ${CACHE}/setup-network-environment -z ${CACHE}/setup-network-environment ${SETUP_NET_ENV_URL}
	@curl -L -o ${CACHE}/openshift-origin.tar.gz   -z ${CACHE}/openshift-origin.tar.gz   ${OPENSHIFT_URL}
	@tar -xf ${CACHE}/openshift-origin.tar.gz -C ${CACHE}/
	@unzip -o "${CACHE}/*.zip" -d ${BINPATH}/

future-upgrade:
	@echo 'Update Go dependencies'
	@go get -u github.com/dbohdan/remarshal
	@go get -u github.com/hashicorp/terraform
	@go get -u github.com/openshift/origin

# Others
# https://terraform.io/docs/commands/graph.html
infrastructure-graph:
	@terraform graph | dot -Tsvg > graph.svg

apps apps-status:
	@oc get apps
#oc describe pods liveness-http

apps-delete:
	@oc stop all -l app=gf
	@oc delete all -l app=gf

create-apps:
	@oc new-app -f services/monitoring.yaml -p SERVER_NAME=befaircloud.me
