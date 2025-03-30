import React, { useState } from "react";
import "./App.css";

function App() {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const handleTerraformAction = async (action) => {
    setLoading(true);
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
      setLoading(false);
    }
  };

  return (
    <div className="App">
      <h1>Terraform Infrastructure Manager</h1>
      {error && <div className="error-message">{error}</div>}
      <div className="button-container">
        <button
          onClick={() => handleTerraformAction("buckets")}
          disabled={loading}
        >
          {loading ? "Processing..." : "Manage S3 Buckets"}
        </button>
        <button onClick={() => handleTerraformAction("ecs")} disabled={loading}>
          {loading ? "Processing..." : "Manage ECS Cluster"}
        </button>
        <button onClick={() => handleTerraformAction("eks")} disabled={loading}>
          {loading ? "Processing..." : "Manage EKS Cluster"}
        </button>
        <button
          onClick={() => handleTerraformAction("instances")}
          disabled={loading}
        >
          {loading ? "Processing..." : "Manage EC2 Instances"}
        </button>
        <button
          onClick={() => handleTerraformAction("users")}
          disabled={loading}
        >
          {loading ? "Processing..." : "Manage IAM Users"}
        </button>
      </div>
    </div>
  );
}

export default App;
