# Part 1 - Connecting a Runner

Part 1 introduces the Humanitec Platform Orchestrator and guides you through connecting it to your workshop Kubernetes cluster.

1. Go to <https://console.humanitec.dev> and register for an account and free org
2. Setup the hctl CLI <https://developer.humanitec.com/platform-orchestrator/docs/integrations/cli/>

    ```sh
    curl -fLO https://github.com/humanitec/hctl/releases/download/v1.38.0/hctl_1.38.0_linux_amd64.tar.gz
    tar xvzf hctl_1.38.0_linux_amd64.tar.gz hctl
    sudo install -o root -g root -m 0755 hctl /usr/local/bin/hctl
    rm hctl_*.tar.gz
    ```

3. Authenticate the CLI with your humctl account

    ```sh
    hctl login
    hctl config set-org ...
    ```

4. Setup terraform variables for Humanitec

    ```sh
    export TF_VAR_humanitec_org_id=...
    ```

5. Run the terraform to set up the runner that allows Humanitec to execute Terraform on the EKS cluster

    ```sh
    cd part_1

    terraform init
    terraform apply
    ```

6. Testing our runner

    ```sh
    hctl create project test-runner
    hctl create runner-rule --set=runner_id=workshop --set=project_id=test-runner
    hctl create environment workshop dev --set=env_type_id=development
    hctl deploy test-runner dev - --no-prompt <<"EOF"
    workloads:
        test: {}
    EOF
    ```

Great! Our EKS-based runner is connected and ready to run deployments.
