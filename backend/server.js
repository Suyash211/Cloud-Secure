const express = require("express");
const { exec } = require("child_process");
const cors = require("cors");
const path = require("path");

const app = express();
app.use(cors());
app.use(express.json());

const TERRAFORM_PATHS = {
  buckets: "../buckets",
  ecs: "../ecs",
  eks: "../eks",
  instances: "../instances",
  users: "../users",
};

app.post("/api/terraform/:action", (req, res) => {
  const { action } = req.params;
  const terraformPath = TERRAFORM_PATHS[action];

  if (!terraformPath) {
    return res.status(400).json({ error: "Invalid action" });
  }

  const absolutePath = path.resolve(__dirname, terraformPath);
  console.log(`Executing Terraform in: ${absolutePath}`);

  // Execute Terraform commands
  exec(
    `cd ${absolutePath} && terraform init && terraform apply -auto-approve`,
    (error, stdout, stderr) => {
      if (error) {
        console.error(`Error: ${error}`);
        return res.status(500).json({
          error: "Terraform execution failed",
          details: error.message,
        });
      }

      console.log(`Terraform output: ${stdout}`);
      res.json({
        message: `Successfully executed Terraform for ${action}`,
        output: stdout,
      });
    }
  );
});

const PORT = process.env.PORT || 3001;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
