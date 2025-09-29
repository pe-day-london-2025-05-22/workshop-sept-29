# Part 1 - Connecting a Runner

Part 1 introduces the Humanitec Platform Orchestrator and guides you through connecting it to your workshop Kubernetes cluster.

1. Go to <https://console.humanitec.dev> and register for an org using your Google/Gmail account
2. Setup the hctl CLI <https://developer.humanitec.com/platform-orchestrator/docs/integrations/cli/>

    ```sh
    curl -fLO https://github.com/humanitec/hctl/releases/download/v1.38.0/hctl_1.38.0_linux_amd64.tar.gz
    tar xvzf hctl_1.38.0_linux_amd64.tar.gz hctl
    sudo install -o root -g root -m 0755 hctl /usr/local/bin/hctl
    rm hctl_*.tar.gz
    ```

3. Authenticate the CLI with your hctl account and set your Humanitec org id in the local configuration

    ```sh
    hctl login
    hctl config set-org <your org id>
    ```
    
    **Note:** You can find your org id in the Humanitec console URL after logging in: `https://console.humanitec.dev/orgs/<your-org-id>/`

4. Setup terraform variable for your Humanitec org

    ```sh
    export TF_VAR_humanitec_org_id=<your org id>
    ```

5. Run the terraform to set up the runner that allows Humanitec to execute Terraform on the EKS cluster

    ```sh
    cd part_1

    terraform init
    terraform apply
    ```
    
    **Success indicator:** You should see terraform outputs including a `runner_url` that you can visit to verify the runner is configured.

6. Testing our runner

    ```sh
    hctl create project workshop
    hctl create runner-rule --set=runner_id=workshop --set=project_id=workshop
    hctl create environment-type production
    hctl create environment workshop prod --set=env_type_id=production
    hctl deploy workshop prod - --no-prompt <<"EOF"
    workloads:
        test: {}
    EOF
    ```

Great! Our EKS-based runner is connected and ready to run deployments. We can see the completed job from our test deployment in the cluster:

```sh
kubectl get jobs -n platform-orchestrator
```
