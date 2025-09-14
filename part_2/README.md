
```
hctl create project workshop2
```

```
hctl create runner-rule --set=runner_id=workshop --set=project_id=workshop2
```

```
hctl create environment workshop2 dev --set=env_type_id=development
```

```
hctl deploy workshop2 dev - --no-prompt <<"EOF"
workloads: {}
EOF
```
