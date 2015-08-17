TERRAFORM_VERSION := 0.6.2
OPENSHIFT_VERSION := 1.0.4-757efd9

#export GOPATH := ${GOPATH}
BINPATH := ${GOPATH}/bin
export PATH := ${GOPATH}/bin:${PATH}
TERRAFORM_URL := https://dl.bintray.com/mitchellh/terraform/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
OPENSHIFT_URL := https://github.com/openshift/origin/releases/download/v1.0.4/openshift-origin-v${OPENSHIFT_VERSION}-linux-amd64.tar.gz
SETUP_NET_ENV_URL := https://github.com/kelseyhightower/setup-network-environment/releases/download/v1.0.0/setup-network-environment


up: clean compile download build
	@terraform plan -out terraform.tfplan
	@terraform apply terraform.tfplan

delete destroy: compile
	@terraform plan -destroy
	@terraform destroy

compile:
	@remarshal \
		-if yaml -i platform/digitalocean.yaml \
		-of json -o terraform.tf.json
	@remarshal \
		-if yaml -i vars.yaml \
		-of json -o terraform.tfvars

c clean soft-clean:
	@rm -rf \
		terraform* \
		platform/utils/{master,node}.tar.gz \
		platform/utils/master/ \
		platform/utils/id_ecdsa*

full-clean: clean
	@rm -rf ${BINPATH}/terraform*
	@rm -rf platform/utils/*.{zip,tar.gz}

download:
	@curl -L -o platform/utils/terraform.zip             -z platform/utils/terraform.zip             ${TERRAFORM_URL}
	@curl -L -o platform/utils/setup-network-environment -z platform/utils/setup-network-environment ${SETUP_NET_ENV_URL}
	@curl -L -o platform/utils/openshift-origin.tar.gz   -z platform/utils/openshift-origin.tar.gz   ${OPENSHIFT_URL}
	@tar -xf platform/utils/openshift-origin.tar.gz -C platform/utils/
	@unzip -o "platform/utils/*.zip" -d ${BINPATH}/

build:
	@ssh-keygen -b 521 -t ecdsa -f platform/utils/id_ecdsa -N ''
	@cd platform/utils && tar -czf master.tar.gz \
		setup-network-environment \
		openshift oc .bashrc
	@cd platform/utils && tar -czf node.tar.gz \
		setup-network-environment \
		openshift oc
	@echo 'Builds done'

# Prerequisites
install:
	@go install github.com/dbohdan/remarshal
	@cp downloads/{oc,openshift} ${BINPATH}/

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
