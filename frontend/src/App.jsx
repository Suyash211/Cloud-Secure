import React, { useState } from "react";
import "./App.css";

function App() {
  const [loadingAction, setLoadingAction] = useState(null);
  const [error, setError] = useState(null);

  const handleTerraformAction = async (action) => {
    setLoadingAction(action);
    setError(null);

    try {
      const response = await fetch(
        `http://localhost:3001/api/terraform/${action}`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
        }
      );

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const data = await response.json();
      alert(data.message);
      console.log("Terraform output:", data.output);
    } catch (error) {
      console.error("Error:", error);
      setError(error.message);
      alert("Error executing Terraform command: " + error.message);
    } finally {
      setLoadingAction(null);
    }
  };

  const buttons = [
    { action: "buckets", label: "Manage S3 Buckets" },
    { action: "ecs", label: "Manage ECS Cluster" },
    { action: "eks", label: "Manage EKS Cluster" },
    { action: "instances", label: "Manage EC2 Instances" },
    { action: "users", label: "Manage IAM Users" },
  ];

  return (
    <div className="App">
      <h1>Terraform Infrastructure Manager</h1>
      {error && <div className="error-message">{error}</div>}
      <div className="button-container">
        {buttons.map(({ action, label }) => (
          <button
            key={action}
            onClick={() => handleTerraformAction(action)}
            disabled={loadingAction !== null}
            className={loadingAction === action ? "loading" : ""}
          >
            {loadingAction === action ? `Processing ${label}...` : label}
          </button>
        ))}
      </div>
    </div>
  );
}

export default App;
