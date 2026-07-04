# CoreBank Infrastructure: Troubleshooting Guide

This document captures the real-world architectural issues we encountered while building the CoreBank polyglot microservice system, analyzing the root cause of each failure and detailing the professional DevOps resolutions.

---

### Problem 1: Go Dependency Initialization in Docker
- **Symptom:** Docker `build` failed for the `corebank-identity-go` container because it could not find a `go.mod` file. 
- **Root Cause:** The host Windows machine did not have Golang installed, so the developer could not run `go mod init` locally before triggering the build.
- **Why It Happened:** We established a strict "Zero-Trust" local development policy—meaning the developer's laptop should not require language runtimes installed to build the project.
- **The Fix:** We injected the dependency initialization directly into the multi-stage `Dockerfile`. 
```dockerfile
# Inside corebank-identity-go/Dockerfile
RUN go mod init corebank-identity-go
RUN go mod tidy
```

---

### Problem 2: Decimal/Float Mismatch in Transaction Engine (500 Error)
- **Symptom:** The React frontend threw a JSON parsing error because it received an "Internal Server Error" page from the backend instead of JSON. 
- **Root Cause:** The `transaction-engine-1` logs showed: `TypeError: unsupported operand type(s) for -=: 'decimal.Decimal' and 'float'`.
- **Why It Happened:** SQLAlchemy maps the PostgreSQL `NUMERIC(15, 2)` balance column into a highly-precise Python `Decimal` object. The incoming REST payload mapped the transaction `amount` to a standard Python `float`. Python fiercely protects against precision loss and blocks subtracting a `float` directly from a `Decimal`.
- **The Fix:** We updated the Pydantic data validation model in `main.py` to enforce `Decimal` types at the API boundary, guaranteeing perfect financial math precision from the API down to the database.
```python
from decimal import Decimal
class TransferRequest(BaseModel):
    amount: Decimal
    destination: str
```

---

### Problem 3: IDE Linter Throwing "Module Not Found" Errors
- **Symptom:** The local IDE highlighted modules like `fastapi`, `pydantic`, and `sqlalchemy` with red squiggly error lines.
- **Root Cause:** The host Windows environment did not have a Python virtual environment (`venv`) or pip installed.
- **Why It Happened:** This is actually a **success indicator**. It proves our containerization architecture successfully decoupled the development environment from the host machine's local dependencies. The code runs flawlessly isolated inside the `transaction-engine` Docker container.
- **The Fix:** No code fix required. The developer can safely ignore the IDE linter warnings, or optionally install Python locally simply to satisfy the IDE's syntax parser.

---

### Problem 4: ArgoCD Fails to Sync Kubernetes Manifests
- **Symptom:** ArgoCD showed an `OutOfSync` status with the error: 
  `The Kubernetes API could not find networking.istio.io/VirtualService`
- **Root Cause:** The advanced GitOps Helm charts attempted to deploy `VirtualService` and `PeerAuthentication` resources, but the local Docker Desktop Kubernetes cluster did not understand what those objects were.
- **Why It Happened:** Standard Kubernetes clusters do not come with a Service Mesh built-in. Istio Custom Resource Definitions (CRDs) must be explicitly installed into the cluster by the Infrastructure team before application developers can leverage them.
- **The Fix:** We downloaded the official Istio installation binary (`istioctl`) and injected the Istio Control Plane (the `demo` profile) directly into the local Kubernetes cluster, giving the API Server the vocabulary it needed to accept the advanced routing rules.
