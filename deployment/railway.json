{
  "build": {
    "builderType": "PACK"
  },
  "deploy": {
    "startCommand": "honcho start -f Procfile"
  },
  "services": [
    {
      "type": "web",
      "name": "frappe-bench",
      "nodeVersion": "20",
      "buildCommand": "pip install --no-cache-dir -r requirements.txt && npm ci",
      "startCommand": "honcho start -f Procfile",
      "instanceCount": 1,
      "memory": "4GB",
      "cpu": 2,
      "envVariables": [
        {
          "key": "RAILWAY_ENVIRONMENT",
          "value": "production"
        },
        {
          "key": "PYTHONUNBUFFERED",
          "value": "1"
        }
      ],
      "buildpacks": [
        {
          "name": "paketo/python"
        },
        {
          "name": "paketo/node"
        }
      ],
      "pullPolicy": "default"
    }
  ],
  "gitSource": {
    "repositoryUrl": "https://github.com/AcumeltPvtLtd/saradata-erp-deploy.git"
  }
}
