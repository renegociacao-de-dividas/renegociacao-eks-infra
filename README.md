# Renegociação de Dívidas — Plataforma Modular com Microsserviços

## 🎯 Caso de Uso:
Simular uma plataforma para renegociação de dívidas. Cada módulo é um microsserviço independente: cadastro, cálculo, proposta, aceite e acompanhamento.

### 🧰 Stack:

- Java 17, Spring Boot 3 (REST APIs + validation)
- Kafka (eventos entre serviços) 
- PostgreSQL / DynamoDB
- AWS ECS (ou Localstack), Terraform, Docker
- Grafana + Prometheus ou DataDog (simulado) para observabilidade
- Testes: JUnit + Testcontainers

### 🛠 Roteiro Técnico:
- Estruturar 5 microsserviços REST com Spring Boot (um para cada domínio).
- Comunicação via eventos Kafka (ex: proposta criada → aguardar aceite).
- Persistência com PostgreSQL (ou simular NoSQL com DynamoDB).
- Observabilidade: métricas básicas com actuator + Prometheus + Grafana.
- Deploy local com Docker Compose (ou ECS com Terraform).
- CI/CD simulado com GitHub Actions e testes automatizados.
