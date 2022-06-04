# Projeto Cloud (AWS, Terraform, Ansible)

## Objetivo
Este projeto teve como objetivo a construção de uma infraestrutura no serviço de cloud da AWS capaz de suportar uma aplicação Django (API) escalável via EKS.

## Terraform
Terraform foi usado para descrever e construir a infraestrutura necessária.
Para que o script `main.tf` seja executado, é preciso configurar as variáveis de ambiente em sua máquina com suas credenciais da AWS e, é preciso que seu usuário tenha as devidas permissões de criação e edição de componentes.

## Ansible
Ansible foi usado para que o deployment fosse feito no cluster EKS gerado pelo Terraform previamente. Alguns passos são necessários para que o deployment seja feito corretamente:
- É necessário possuir o `kubectl` e o `awscli` instalados e funcionais em sua máquina;
- É necessário configurar seu kubectl para que seus comandos tenham como target seu cluster gerado pelo Terraform. Para isso, execute `aws eks update-kubeconfig --region us-east-1 --name EKSCluter`. O comando leva em conta que você está trabalhando na região `us-east-1` e que seu cluster EKS possua o nome `EKSCluster`;
- O método usado para escalonamento de pods leva em conta que seu cluster possua um metrics server funcional que fornecerá informações básicas de uso de CPU de seus pods para o `Horizontal Pod Autoscaler`. Por isso, antes de executar o playbook, implante o `metrics-server` do kubernetes-sigs em seu cluster. Um guia pode ser encontrado em https://docs.aws.amazon.com/eks/latest/userguide/metrics-server.html;
- Da maneira com que o cluster está configurado o metrics-server não conseguirá fornecer as informações necessárias dos pods ao horizontal pod autoscaler. É necessário que os security groups do cluster e dos nodes liberem acesso de entrada e saida de todos os protocolos a partir de seu ip. Além disso, é necessário alterar o deployment do metrics-server, adicionando `hostNetwork: true` dentro de `spec` e `--kubelet-insecure-tls` ao argumentos do deployment. Estes problemas são nativos do metrics-server quando se trabalha usando EKS, por isso, minha infraestrutura e meu deployment não levam em conta as correções. 

## Infraestrutura
![[infra.png]]
