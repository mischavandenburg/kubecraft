# Pipeline Mock-up

Create an infrastructure for home-labs for a very simple web app.

## The objective is to gain practice on the following items

- Version Control Systems - Git, GitHub
- CI/CD Tools - Azure DevOps Pipelines, Tekton and Gitlab CI
- Containerization and Orchestration - Kubernetes
- Container Registries - Docker Hub
- Infrastructure as Code (IaC) - Helm, Terraform
- Monitoring and Logging - Prometheus, Grafana
- Service Mesh - Istio
- GitOps Tools - Flux, Argo CD

## Guiding principles

1. The above should not exclude porting to cloud providers for the more advanced professionals.
2. Each part should be as decoupled as possible to allow porting and maintenance but most importantly modularity so that different implementations could allow focussing on specific aspects. An initial version could be on Proxmox but then people could contribute to running it on say VirtualBox or leave this layer entirely and run on Docker Desktop.
3. In order to manage complexity, we should aim to pin down the baseline project elements listed above should leaving variations individual endeavours or side-projects.
4. As for the app, some of us are also developers and maybe could provide suggestions as to what could be more suitable but something that would allow to easily make changes to the code and verify the deployment afterwards. A simple web page that allows to change background colour, some text, or some CSS attribute, etc.
